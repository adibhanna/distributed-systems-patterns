# gRPC Streaming and Integration

Use this when designing service-to-service communication with gRPC, particularly streaming RPCs. Streaming is the right tool for low-latency request/response with backpressure inside one trust boundary; it is the wrong tool when you actually need a broker for fan-out, replay, or non-Go consumers.

## The four method types

| Method type            | Shape                            | Fits when                                                              |
| ---------------------- | -------------------------------- | ---------------------------------------------------------------------- |
| Unary                  | one request, one response        | Synchronous reads, simple commands, anything you would write as REST   |
| Server streaming       | one request, many responses      | Live tail, paginated push, single-consumer pub-sub within one process  |
| Client streaming       | many requests, one response      | Upload, batch ingest, server-side aggregation                          |
| Bidirectional streaming| many requests, many responses    | Interactive sessions, RPC-over-stream, session-state per connection    |

## Pattern mapping

- Server streaming -> Publish-Subscribe Channel for one client. Fine for a single consumer. Add a broker the moment you have a second.
- Bidi -> Request-Reply with Correlation Identifier per stream message. Works when both sides own the protocol; brittle when used as a substitute for a real message bus.
- Client streaming -> Aggregator on the server. The server sees the whole batch and emits one summary; ideal for upload-and-compute.
- Unary with deadlines -> Remote Procedure Invocation, full stop. Treat it as RPC, not a messaging substitute.

## Deadline propagation

Deadlines flow through context. A gRPC server hands you a `context.Context` whose deadline is set from the client's deadline; downstream calls inherit it via `WithDeadline` or `WithTimeout`. Do not start a new background context inside an RPC handler — you sever the deadline chain.

```go
// Pattern: Message Expiration / TTL applied at the call boundary.
ctx, cancel := context.WithTimeout(ctx, 200*time.Millisecond)
defer cancel()
resp, err := downstream.Get(ctx, req)
```

For streams, set per-stream deadlines on long-lived connections only when the business requires a cap; otherwise the client should close the stream when it is done. Do not use deadlines as a replacement for explicit health checks.

## Retry policy

gRPC has a native retry config in service config JSON:

```json
{
  "methodConfig": [{
    "name": [{ "service": "orders.OrdersService" }],
    "retryPolicy": {
      "maxAttempts": 4,
      "initialBackoff": "0.1s",
      "maxBackoff": "2s",
      "backoffMultiplier": 2,
      "retryableStatusCodes": ["UNAVAILABLE", "DEADLINE_EXCEEDED"]
    }
  }]
}
```

Status-code mapping for retry safety:

| Code                | Retryable? | Note                                                                                  |
| ------------------- | ---------- | ------------------------------------------------------------------------------------- |
| `UNAVAILABLE`       | yes        | Transport failure; safe with idempotent handlers                                      |
| `DEADLINE_EXCEEDED` | sometimes  | Only if the call is idempotent; otherwise the server may have committed already      |
| `RESOURCE_EXHAUSTED`| with care  | Honor backoff; this is "slow down," not "try again immediately"                       |
| `ABORTED`           | yes        | Concurrency/version conflict; retry with fresh state                                  |
| `INTERNAL`          | no         | Server bug; retrying hides it                                                         |
| `INVALID_ARGUMENT`  | no         | Will fail again the same way                                                          |
| `PERMISSION_DENIED` | no         | Auth/IAM problem                                                                      |
| `UNAUTHENTICATED`   | no, until refresh | Refresh credentials, then retry                                                |

For at-least-once semantics, attach an idempotency key in metadata and have the server deduplicate. This is the same Idempotent Receiver pattern, applied across an RPC boundary.

## Backpressure

`ServerStream.Send` blocks when the underlying flow-control window is full. Treat the per-stream `chan` between your producer goroutine and the gRPC send loop as a bounded queue — a watermark of "queue is X% full" is your in-process backpressure signal.

## Go server-streaming example

```go
package events

import (
	"context"
	"errors"
	"fmt"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

// EventStream sends per-account events until the client disconnects.
// Pattern: Publish-Subscribe Channel (single subscriber).
// Pattern: Message History - propagate trace + correlation ids in metadata.
func (s *Server) EventStream(req *EventRequest, stream EventService_EventStreamServer) error {
	ctx := stream.Context()

	// Deadline propagation: respect the client's deadline.
	if dl, ok := ctx.Deadline(); ok {
		s.log.Info("stream deadline", "deadline", dl.UTC())
	}

	// Pattern: Idempotent Receiver - dedupe by idempotency-key from metadata.
	md, _ := metadata.FromIncomingContext(ctx)
	idemKey := firstHeader(md, "idempotency-key")
	if idemKey == "" {
		return status.Error(codes.InvalidArgument, "idempotency-key required")
	}

	// Bounded subscription channel; back-pressure surfaces as a slow consumer.
	sub, cancel, err := s.bus.Subscribe(ctx, req.AccountId, 256)
	if err != nil {
		return mapErr(err)
	}
	defer cancel()

	heartbeat := time.NewTicker(20 * time.Second)
	defer heartbeat.Stop()

	for {
		select {
		case <-ctx.Done():
			// Always honor ctx.Done() in the send loop.
			return status.FromContextError(ctx.Err()).Err()
		case <-heartbeat.C:
			if err := stream.Send(&Event{Type: "heartbeat", Time: time.Now().Unix()}); err != nil {
				return mapErr(err)
			}
		case ev, ok := <-sub:
			if !ok {
				return nil
			}
			if err := stream.Send(ev); err != nil {
				return mapErr(err)
			}
		}
	}
}

// mapErr converts internal errors to canonical gRPC status codes.
func mapErr(err error) error {
	switch {
	case errors.Is(err, context.Canceled):
		return status.Error(codes.Canceled, "client canceled")
	case errors.Is(err, context.DeadlineExceeded):
		return status.Error(codes.DeadlineExceeded, "stream deadline exceeded")
	case errors.Is(err, ErrTransient):
		return status.Errorf(codes.Unavailable, "transient: %v", err)
	default:
		return status.Errorf(codes.Internal, "stream error: %v", err)
	}
}

func firstHeader(md metadata.MD, key string) string {
	if vals := md.Get(key); len(vals) > 0 {
		return vals[0]
	}
	return ""
}

var ErrTransient = fmt.Errorf("transient")
```

The send loop checks `ctx.Done()` first in every iteration; the heartbeat keeps NAT/proxy paths from idle-timeouts; the bounded `sub` channel turns broker pressure into a slow-consumer signal we can monitor.

## Anti-patterns

- Long-lived bidi stream as a substitute for a real broker. You will reinvent durable subscribers, replay, and dead-letter queues badly.
- Spawning unbounded goroutines per stream. Each connected client should map to a fixed-size buffer, not "one per event."
- Ignoring `ctx.Done()` in send loops. This leaks goroutines on every disconnect; tests pass and prod accumulates.
- No health-check stream for long-lived connections. NAT/proxy paths drop idle TCP connections silently after minutes.
- Treating `DEADLINE_EXCEEDED` as automatically retryable for write RPCs. The server may have committed before the deadline fired.
- Burying the idempotency-key in the request body instead of metadata. Metadata is the right home for it; bodies get versioned.

## When to graduate from gRPC streams to a broker

Move to Kafka / NATS / Pub/Sub when any of these are true:

- More than one independent subscriber wants the same data.
- Consumers need durable replay across restarts.
- Retention longer than the longest connection lifetime.
- Non-Go consumers, especially data-pipeline teams.
- Cross-org or cross-trust-boundary delivery — gRPC streams across that boundary are an anti-pattern.

The pattern stays the same — Publish-Subscribe Channel, Datatype Channel, Idempotent Receiver — only the realization changes.

## References

- gRPC service config retries: https://grpc.io/docs/guides/retry/
- gRPC deadlines: https://grpc.io/docs/guides/deadlines/
- gRPC error model: https://grpc.io/docs/guides/error/
- gRPC keepalive: https://grpc.io/docs/guides/keepalive/
