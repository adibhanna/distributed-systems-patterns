# Webhook Security (Go)

Use this when building an HTTP receiver for third-party webhooks: payment providers, source-control hosts, chat platforms, partner integrations. The producer is outside your trust boundary, will retry aggressively on failure, and may replay deliveries — the receiver must verify, dedupe, and accept durably before doing any business work.

## Why webhooks differ from internal events

- The producer is untrusted. Anyone can hit the URL; signature verification is the trust boundary, not network ACLs.
- The producer retries on any non-2xx response, often with exponential backoff for hours or days. Slow handlers cause duplicate deliveries.
- Replay is real: providers re-send during outages, and attackers can re-send captured payloads if the timestamp window is unbounded.
- The wire format is whatever the provider chose. Trace context, schema version, and partition keys are not guaranteed.
- Compliance concerns differ: PCI/PII may arrive in payloads you did not design.

## The seven receiver checks

1. Read the raw request body before any parsing. Signatures cover bytes, not parsed structures.
2. Verify the provider signature with a constant-time compare. Use `crypto/hmac.Equal` or `crypto/subtle.ConstantTimeCompare`.
3. Validate timestamp freshness. Reject deliveries with skew greater than the provider's documented window (commonly 5 minutes).
4. Dedupe by provider delivery id. Persist the id in a store with TTL longer than the provider's max retry window.
5. Store the raw signed message if compliance and retention policy allow it. This is the only artifact a customer can use to dispute a webhook event.
6. Return 2xx quickly after durable accept. Do not call downstream services synchronously inside the HTTP handler.
7. Process asynchronously off a queue or internal channel. The HTTP handler is a Channel Adapter, not the worker.

## Complete Go handler

```go
package webhooks

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	maxBodyBytes    = 1 << 20 // 1 MiB; webhook bodies are small.
	freshnessWindow = 5 * time.Minute
)

type Receiver struct {
	signingSecret []byte
	db            *pgxpool.Pool
	work          chan<- RawDelivery // bounded internal channel.
}

type RawDelivery struct {
	DeliveryID string
	Body       []byte
	ReceivedAt time.Time
}

// Handle implements the seven webhook receiver checks.
// Pattern: Channel Adapter - bridge external HTTP to internal events.
// Pattern: Idempotent Receiver - dedupe on provider delivery id.
// Pattern: Invalid Message Channel - reject malformed/unsigned at the boundary.
func (r *Receiver) Handle(w http.ResponseWriter, req *http.Request) {
	ctx := req.Context()

	// 1. Read raw body before parsing.
	body, err := io.ReadAll(io.LimitReader(req.Body, maxBodyBytes))
	if err != nil {
		http.Error(w, "read body", http.StatusBadRequest)
		return
	}

	// 2 + 3. Verify signature and timestamp from a Stripe-style header
	//        of the form: t=<unix>,v1=<hex-hmac>.
	sig := req.Header.Get("Stripe-Signature")
	ts, mac, err := parseSignatureHeader(sig)
	if err != nil {
		http.Error(w, "bad signature header", http.StatusBadRequest)
		return
	}

	if skew := time.Since(ts); skew > freshnessWindow || skew < -freshnessWindow {
		http.Error(w, "stale timestamp", http.StatusBadRequest)
		return
	}

	expected := computeMAC(r.signingSecret, ts, body)
	if subtle.ConstantTimeCompare(mac, expected) != 1 {
		http.Error(w, "invalid signature", http.StatusUnauthorized)
		return
	}

	// 4. Dedupe by provider delivery id.
	deliveryID := req.Header.Get("Stripe-Event-Id")
	if deliveryID == "" {
		http.Error(w, "missing delivery id", http.StatusBadRequest)
		return
	}
	inserted, err := r.markDelivery(ctx, deliveryID, body)
	if err != nil {
		http.Error(w, "store failure", http.StatusServiceUnavailable)
		return
	}
	if !inserted {
		// Already accepted; idempotent OK keeps the provider from retrying.
		w.WriteHeader(http.StatusOK)
		return
	}

	// 6 + 7. Hand off to async worker; do not do business work in the HTTP handler.
	select {
	case r.work <- RawDelivery{DeliveryID: deliveryID, Body: body, ReceivedAt: time.Now().UTC()}:
		w.WriteHeader(http.StatusOK)
	case <-ctx.Done():
		http.Error(w, "shutting down", http.StatusServiceUnavailable)
	}
}

// computeMAC implements Stripe's `t=...,v1=...` signing scheme.
// Pattern: Format Indicator - the version prefix lets us rotate schemes safely.
func computeMAC(secret []byte, ts time.Time, body []byte) []byte {
	signed := strconv.FormatInt(ts.Unix(), 10) + "." + string(body)
	mac := hmac.New(sha256.New, secret)
	mac.Write([]byte(signed))
	sum := mac.Sum(nil)
	hexed := make([]byte, hex.EncodedLen(len(sum)))
	hex.Encode(hexed, sum)
	return hexed
}

func parseSignatureHeader(h string) (time.Time, []byte, error) {
	var tsStr, v1 string
	for _, part := range strings.Split(h, ",") {
		k, v, ok := strings.Cut(part, "=")
		if !ok {
			continue
		}
		switch strings.TrimSpace(k) {
		case "t":
			tsStr = strings.TrimSpace(v)
		case "v1":
			v1 = strings.TrimSpace(v)
		}
	}
	if tsStr == "" || v1 == "" {
		return time.Time{}, nil, errors.New("missing fields")
	}
	unix, err := strconv.ParseInt(tsStr, 10, 64)
	if err != nil {
		return time.Time{}, nil, err
	}
	return time.Unix(unix, 0), []byte(v1), nil
}

// markDelivery inserts the delivery id; returns false if already present.
// Pattern: Idempotent Receiver backed by a unique constraint.
func (r *Receiver) markDelivery(ctx context.Context, id string, body []byte) (bool, error) {
	var inserted bool
	err := r.db.QueryRow(ctx, `
		insert into webhook_deliveries (provider, delivery_id, body, received_at)
		values ('stripe', $1, $2, now())
		on conflict do nothing
		returning true`,
		id, body,
	).Scan(&inserted)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, nil
	}
	return inserted, err
}
```

The `webhook_deliveries` table should retain rows for at least the provider's longest retry window plus your audit retention; for Stripe, that is days, not minutes.

## Provider quirks

**Stripe.** Header is `Stripe-Signature: t=<unix>,v1=<hex>`. Signed payload is `t.<raw-body>`. Multiple `v1=` values mean an active key and a rotating key — accept either.

**GitHub.** Header is `X-Hub-Signature-256: sha256=<hex>`. No timestamp in the header — GitHub does not protect against replay at the signature layer; rely on `X-GitHub-Delivery` for dedupe and treat the IP allowlist as defense-in-depth, not a primary control.

**Slack.** Headers are `X-Slack-Request-Timestamp` and `X-Slack-Signature`. Signed payload is `v0:<ts>:<body>`. Slack's documented freshness window is 5 minutes; reject anything older.

## Standard Webhooks specification

The Standard Webhooks spec (https://www.standardwebhooks.com/) is gaining adoption across newer providers — Svix, Resend, and Clerk all emit it natively. It standardizes three headers: `webhook-id` (delivery id for dedupe), `webhook-timestamp` (Unix seconds for freshness), and `webhook-signature` (one or more space-separated `v1,<base64-hmac-sha256>` values, computed over `<id>.<timestamp>.<body>`). Multiple values support key rotation; accept any match.

For new providers, prefer this format — it removes per-provider parsing boilerplate. For legacy providers (Stripe, GitHub, Slack), keep their established schemes; do not retrofit the standard onto an existing contract.

```go
id := req.Header.Get("webhook-id")
ts := req.Header.Get("webhook-timestamp")
sigHeader := req.Header.Get("webhook-signature") // e.g. "v1,<base64> v1,<base64>"
signed := id + "." + ts + "." + string(body)
mac := hmac.New(sha256.New, secret)
mac.Write([]byte(signed))
expected := base64.StdEncoding.EncodeToString(mac.Sum(nil))
// Compare each "v1,<base64>" entry with subtle.ConstantTimeCompare against expected.
```

## Anti-patterns

- Comparing signatures with `==` or `bytes.Equal`. Both leak timing. Always use `crypto/hmac.Equal` or `crypto/subtle.ConstantTimeCompare`.
- Calling `json.Decode(req.Body, &payload)` before signature verification. The signature covers bytes; once you parse, you have lost the canonical form.
- Logging the raw signing secret, full headers, or full payload in a debug log. Treat the secret as a credential and the payload as customer data.
- Reusing a single signing key across dev, staging, and production. Rotate per environment, and rotate on employee departure.
- Returning 2xx after writing to an in-memory channel that has not been drained on shutdown. Use a durable queue or wait for the row to be committed.
- Doing the business side effect inside the HTTP handler. Slow downstreams cause provider retries, which become duplicates.

## Testing

- Round-trip signature test: sign a known body with the secret, hand it to the handler, expect 200.
- Replay-window test: shift the timestamp 6 minutes into the past and expect 400.
- Malformed signature test: flip one byte in the MAC and expect 401; assert the handler rejects in constant time using a benchmark with two near-equal inputs.
- Duplicate delivery test: post the same `Stripe-Event-Id` twice; the second call must return 200 without enqueuing a second job.
- Body-tampering test: change one byte after signing; expect 401.
- Compliance test: assert the secret is not present in any log line emitted by the handler under failure modes.

## References

- Stripe webhook signing: https://stripe.com/docs/webhooks/signatures
- GitHub webhook security: https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries
- Slack request signing: https://api.slack.com/authentication/verifying-requests-from-slack
- OWASP Webhook security cheat sheet: https://cheatsheetseries.owasp.org/cheatsheets/Webhook_Security_Cheat_Sheet.html
- Standard Webhooks specification: https://www.standardwebhooks.com/
