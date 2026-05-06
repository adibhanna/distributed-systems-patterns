# Production Go Examples

These snippets are intentionally framework-light. Adapt broker/database clients to the repo, but preserve the visible pattern boundaries: outbox, idempotency, retry, DLQ, trace propagation, and commit-after-state-change.

## Dependencies

Common production choices:

```bash
go get github.com/cloudevents/sdk-go/v2
go get github.com/google/uuid
go get github.com/jackc/pgx/v5
go get github.com/twmb/franz-go/pkg/kgo
go get go.opentelemetry.io/otel
go get go.opentelemetry.io/otel/propagation
go get go.temporal.io/sdk
```

Use the repository's existing client libraries if they are already standardized.

## Kafka header carrier for OpenTelemetry

```go
package messaging

import "github.com/twmb/franz-go/pkg/kgo"

// KafkaHeaders adapts franz-go record headers to OpenTelemetry's TextMapCarrier.
// Pattern: Message History - propagate trace context across broker hops.
type KafkaHeaders []kgo.RecordHeader

func (h KafkaHeaders) Get(key string) string {
	for _, header := range h {
		if header.Key == key {
			return string(header.Value)
		}
	}
	return ""
}

func (h *KafkaHeaders) Set(key, value string) {
	for i := range *h {
		if (*h)[i].Key == key {
			(*h)[i].Value = []byte(value)
			return
		}
	}
	*h = append(*h, kgo.RecordHeader{Key: key, Value: []byte(value)})
}

func (h KafkaHeaders) Keys() []string {
	keys := make([]string, 0, len(h))
	for _, header := range h {
		keys = append(keys, header.Key)
	}
	return keys
}
```

Register the propagator once at process startup:

```go
otel.SetTextMapPropagator(
	propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	),
)
```

## OpenTelemetry messaging semantic conventions

The OpenTelemetry Messaging Semantic Conventions stabilized in late 2024 and now define a portable attribute set for producer and consumer spans. APMs and SLO platforms (Honeycomb, Datadog, Grafana Tempo, AWS X-Ray) increasingly key off these conventional names for messaging dashboards, lag charts, and DLQ alerts; setting them by hand pays off immediately in vendor-supplied views.

Producer span attributes:

- `messaging.system="kafka"`
- `messaging.destination.name="orders.placed.v1"`
- `messaging.kafka.message.key=<key>`
- `messaging.operation.name="publish"`
- `messaging.message.id=<event-id>`

Consumer span attributes: the same set plus `messaging.consumer.group.name`, `messaging.kafka.offset`, and `messaging.operation.type="receive"`.

```go
import "go.opentelemetry.io/otel/attribute"

ctx, span := tracer.Start(ctx, "orders.placed.v1 publish")
span.SetAttributes(
	attribute.String("messaging.system", "kafka"),
	attribute.String("messaging.destination.name", "orders.placed.v1"),
	attribute.String("messaging.kafka.message.key", order.ID),
	attribute.String("messaging.operation.name", "publish"),
	attribute.String("messaging.message.id", event.ID()),
)
defer span.End()
```

Reference: https://opentelemetry.io/docs/specs/semconv/messaging/

## Producer: Transactional Outbox

Schema:

```sql
create table outbox_events (
	id uuid primary key,
	aggregate_type text not null,
	aggregate_id text not null,
	event_type text not null,
	payload jsonb not null,
	headers jsonb not null default '{}',
	created_at timestamptz not null default now(),
	published_at timestamptz
);

create index outbox_events_unpublished_idx
	on outbox_events (created_at)
	where published_at is null;
```

Go:

```go
package orders

import (
	"context"
	"encoding/json"
	"time"

	cloudevents "github.com/cloudevents/sdk-go/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/propagation"
)

type Order struct {
	ID         string
	CustomerID string
	TotalCents int64
}

type OrderPlaced struct {
	OrderID    string `json:"order_id"`
	CustomerID string `json:"customer_id"`
	TotalCents int64  `json:"total_cents"`
}

// PlaceOrder stores domain state and the integration event atomically.
// Pattern: Transactional Outbox - avoids db-write-then-publish dual-write.
func PlaceOrder(ctx context.Context, tx pgx.Tx, order Order) error {
	if _, err := tx.Exec(ctx, `
		insert into orders (id, customer_id, total_cents, created_at)
		values ($1, $2, $3, now())`,
		order.ID, order.CustomerID, order.TotalCents,
	); err != nil {
		return err
	}

	event := cloudevents.NewEvent()
	event.SetID(uuid.NewString())                      // Pattern: Correlation Identifier / dedupe key.
	event.SetSource("orders-service")
	event.SetType("com.acme.orders.placed.v1")         // Pattern: Datatype Channel.
	event.SetSubject(order.ID)                         // Pattern: per-order ordering key.
	event.SetTime(time.Now().UTC())
	event.SetExtension("partitionkey", order.ID)
	event.SetExtension("correlationid", correlationID(ctx))

	if err := event.SetData(cloudevents.ApplicationJSON, OrderPlaced{
		OrderID:    order.ID,
		CustomerID: order.CustomerID,
		TotalCents: order.TotalCents,
	}); err != nil {
		return err
	}

	traceHeaders := propagation.MapCarrier{}
	otel.GetTextMapPropagator().Inject(ctx, traceHeaders) // Pattern: Message History.

	payload, err := json.Marshal(event)
	if err != nil {
		return err
	}
	headers, err := json.Marshal(map[string]string(traceHeaders))
	if err != nil {
		return err
	}

	_, err = tx.Exec(ctx, `
		insert into outbox_events (id, aggregate_type, aggregate_id, event_type, payload, headers)
		values ($1, 'order', $2, $3, $4, $5)`,
		event.ID(), order.ID, event.Type(), payload, headers,
	)
	return err
}

type ctxKey int

const correlationIDKey ctxKey = iota

func correlationID(ctx context.Context) string {
	if value, ok := ctx.Value(correlationIDKey).(string); ok && value != "" {
		return value
	}
	return uuid.NewString()
}
```

Production note: publish the outbox with Debezium Outbox Event Router, a Kafka Connect JDBC source, or a small polling publisher that claims rows with `select ... for update skip locked`. Do not publish directly inside the request handler after committing the DB transaction.

## Consumer: Idempotent Receiver + DLQ

Inbox schema:

```sql
create table consumer_inbox (
	consumer_name text not null,
	event_source text not null,
	event_id text not null,
	processed_at timestamptz not null default now(),
	primary key (consumer_name, event_source, event_id)
);
```

```go
package inventory

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"math/rand/v2"
	"slices"
	"time"

	messaging "github.com/acme/app/internal/messaging" // Replace with the package that defines KafkaHeaders.
	cloudevents "github.com/cloudevents/sdk-go/v2"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/twmb/franz-go/pkg/kgo"
	"go.opentelemetry.io/otel"
)

var (
	ErrTransient = errors.New("transient dependency failure")
	ErrPermanent = errors.New("permanent message failure")
)

type OrderPlaced struct {
	OrderID string `json:"order_id"`
}

type Consumer struct {
	cl  *kgo.Client // shared producer + consumer
	dlq string      // DLQ topic name (produced via cl)
	db  *pgxpool.Pool
	log *slog.Logger
}

// Handle processes one Kafka record.
// Pattern: Event-Driven Consumer + Idempotent Receiver + Dead Letter Channel.
func (c *Consumer) Handle(ctx context.Context, record *kgo.Record) error {
	headers := messaging.KafkaHeaders(record.Headers)
	ctx = otel.GetTextMapPropagator().Extract(ctx, &headers) // Pattern: Message History.

	var event cloudevents.Event
	if err := json.Unmarshal(record.Value, &event); err != nil {
		return c.deadLetterAndCommit(ctx, record, "invalid-json", err)
	}
	if event.Type() != "com.acme.orders.placed.v1" {
		return c.deadLetterAndCommit(ctx, record, "unexpected-event-type", ErrPermanent)
	}

	var data OrderPlaced
	if err := event.DataAs(&data); err != nil {
		return c.deadLetterAndCommit(ctx, record, "invalid-payload", err)
	}

	tx, err := c.db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("%w: begin inbox transaction: %v", ErrTransient, err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	// Pattern: Idempotent Receiver - the inbox row and side effect commit together.
	inserted, err := markInbox(ctx, tx, "inventory-consumer", event.Source(), event.ID())
	if err != nil {
		return fmt.Errorf("%w: mark inbox: %v", ErrTransient, err)
	}
	if !inserted {
		c.log.Info("duplicate message skipped", "event_id", event.ID(), "source", event.Source(), "topic", record.Topic)
		return c.commit(ctx, record)
	}

	if err := c.reserveInventoryTx(ctx, tx, data.OrderID); err != nil {
		if errors.Is(err, ErrTransient) {
			return err // Let the runner retry with bounded backoff.
		}
		return c.deadLetterAndCommit(ctx, record, "permanent-processing-failure", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("%w: commit inbox transaction: %v", ErrTransient, err)
	}

	// Pattern: Transactional Client boundary - commit offset only after side effect succeeds.
	return c.commit(ctx, record)
}

func markInbox(ctx context.Context, tx pgx.Tx, consumerName, eventSource, eventID string) (bool, error) {
	var inserted bool
	err := tx.QueryRow(ctx, `
		insert into consumer_inbox (consumer_name, event_source, event_id)
		values ($1, $2, $3)
		on conflict do nothing
		returning true`,
		consumerName, eventSource, eventID,
	).Scan(&inserted)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, nil
	}
	return inserted, err
}

func (c *Consumer) reserveInventoryTx(ctx context.Context, tx pgx.Tx, orderID string) error {
	_, err := tx.Exec(ctx, `
		insert into inventory_reservations (order_id, reserved_at)
		values ($1, now())
		on conflict (order_id) do nothing`,
		orderID,
	)
	return err
}

func (c *Consumer) deadLetterAndCommit(ctx context.Context, record *kgo.Record, reason string, cause error) error {
	dlqHeaders := slices.Clone(record.Headers)
	dlqHeaders = append(dlqHeaders,
		kgo.RecordHeader{Key: "dlq-reason", Value: []byte(reason)},
		kgo.RecordHeader{Key: "dlq-error", Value: []byte(cause.Error())},
		kgo.RecordHeader{Key: "dlq-owner", Value: []byte("inventory-team")},
	)

	// Pattern: Dead Letter Channel - publish before committing the source offset.
	if err := c.cl.ProduceSync(ctx, &kgo.Record{
		Topic:     c.dlq,
		Key:       record.Key,
		Value:     record.Value,
		Headers:   dlqHeaders,
		Timestamp: time.Now().UTC(),
	}).FirstErr(); err != nil {
		return fmt.Errorf("%w: dlq publish failed: %v", ErrTransient, err)
	}

	c.log.Warn("message dead-lettered",
		"topic", record.Topic,
		"partition", record.Partition,
		"offset", record.Offset,
		"reason", reason,
		"error", cause,
	)
	return c.commit(ctx, record)
}

func (c *Consumer) commit(ctx context.Context, record *kgo.Record) error {
	if err := c.cl.CommitRecords(ctx, record); err != nil {
		return fmt.Errorf("%w: source commit failed: %v", ErrTransient, err)
	}
	return nil
}
```

Client setup for both production and consumption:

```go
// Pattern: Messaging Gateway - one kgo.Client serves producer and consumer.
cl, err := kgo.NewClient(
	kgo.SeedBrokers("kafka:9092"),
	kgo.ConsumerGroup("inventory-consumer"),
	kgo.ConsumeTopics("orders.placed.v1"),
	kgo.DisableAutoCommit(),                  // commit only after durable side effects
	kgo.RequiredAcks(kgo.AllISRAcks()),       // acks=all on producer path
	kgo.ProducerBatchCompression(kgo.SnappyCompression()),
)
if err != nil {
	return err
}
defer cl.Close()
```

On Kafka 3.7+/4.0 with KIP-848 cooperative rebalance, franz-go negotiates the new protocol automatically when the broker supports it; no client option needed.

Runner with bounded retry and DLQ on exhaustion:

```go
func (c *Consumer) Run(ctx context.Context) error {
	for {
		if ctx.Err() != nil {
			return ctx.Err()
		}
		fetches := c.cl.PollFetches(ctx)
		if errs := fetches.Errors(); len(errs) > 0 {
			// First fetch error is sufficient; log others if useful.
			return fmt.Errorf("kafka poll: %w", errs[0].Err)
		}
		var iterErr error
		fetches.EachRecord(func(record *kgo.Record) {
			if iterErr != nil {
				return // stop iterating after a fatal error
			}
			if err := retry(ctx, 5, 200*time.Millisecond, func() error {
				return c.Handle(ctx, record)
			}); err != nil {
				// Pattern: Dead Letter Channel - retry exhaustion is visible and recoverable.
				if dlqErr := c.deadLetterAndCommit(ctx, record, "retry-exhausted", err); dlqErr != nil {
					iterErr = dlqErr
				}
			}
		})
		if iterErr != nil {
			return iterErr
		}
	}
}

func retry(ctx context.Context, maxAttempts int, baseDelay time.Duration, fn func() error) error {
	var last error
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		if err := fn(); err != nil {
			last = err
			if !errors.Is(err, ErrTransient) {
				return err
			}
		} else {
			return nil
		}

		exp := attempt - 1
		if exp > 6 {
			exp = 6
		}
		delay := baseDelay * time.Duration(1<<exp)
		jitterMax := delay / 2
		if jitterMax <= 0 {
			jitterMax = time.Millisecond
		}
		jitter := time.Duration(rand.Int64N(int64(jitterMax)))
		timer := time.NewTimer(delay + jitter)
		select {
		case <-ctx.Done():
			timer.Stop()
			return ctx.Err()
		case <-timer.C:
		}
	}
	return last
}
```

## Temporal Process Manager

Use a Process Manager when the business outcome spans multiple steps and needs durable state, timeouts, retries, and compensations.

```go
package fulfillment

import (
	"time"

	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/workflow"
)

type FulfillOrderInput struct {
	OrderID   string
	PaymentID string
}

// FulfillOrderWorkflow is the visible Process Manager for order fulfillment.
// Pattern: Process Manager (Saga) - commands steps and compensates completed work.
func FulfillOrderWorkflow(ctx workflow.Context, in FulfillOrderInput) error {
	ctx = workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
		StartToCloseTimeout: 30 * time.Second,
		RetryPolicy: &temporal.RetryPolicy{
			InitialInterval:    time.Second,
			BackoffCoefficient: 2,
			MaximumInterval:    30 * time.Second,
			MaximumAttempts:    5,
		},
	})

	compensations := make([]func(workflow.Context) error, 0, 2)
	// Pattern: Compensation - run rollback on a disconnected workflow context so
	// workflow cancellation does not skip rollback activities.
	compensate := func(ctx workflow.Context) error {
		cctx, cancel := workflow.NewDisconnectedContext(ctx)
		defer cancel()
		cctx = workflow.WithActivityOptions(cctx, workflow.ActivityOptions{
			StartToCloseTimeout: 30 * time.Second,
		})
		var firstErr error
		for i := len(compensations) - 1; i >= 0; i-- {
			if err := compensations[i](cctx); err != nil && firstErr == nil {
				firstErr = err
			}
		}
		return firstErr
	}

	// Pattern: Command Message - ask payments service to charge.
	if err := workflow.ExecuteActivity(ctx, ChargePayment, in.PaymentID).Get(ctx, nil); err != nil {
		return err
	}
	compensations = append(compensations, func(ctx workflow.Context) error {
		return workflow.ExecuteActivity(ctx, RefundPayment, in.PaymentID).Get(ctx, nil)
	})

	// Pattern: Command Message - ask inventory service to reserve.
	if err := workflow.ExecuteActivity(ctx, ReserveInventory, in.OrderID).Get(ctx, nil); err != nil {
		_ = compensate(ctx)
		return err
	}
	compensations = append(compensations, func(ctx workflow.Context) error {
		return workflow.ExecuteActivity(ctx, ReleaseInventory, in.OrderID).Get(ctx, nil)
	})

	if err := workflow.ExecuteActivity(ctx, CreateShipment, in.OrderID).Get(ctx, nil); err != nil {
		_ = compensate(ctx)
		return err
	}
	return nil
}
```

Temporal-specific rules:

- Workflow code must be deterministic: no `time.Now`, random UUIDs, network calls, goroutines, or unordered map iteration inside workflows.
- Put side effects in Activities. Make every Activity idempotent with the workflow id or business id.
- Use explicit error checks for compensation. Do not rely on panic recovery in deferred functions inside Workflow code.
- Version long-running workflows before changing activity signatures or event history behavior.

## Tests to require

- Producer unit test: outbox row is written in the same DB transaction as domain state.
- Consumer property/table test: same event delivered twice changes state once.
- Poison-message test: invalid payload goes to DLQ and the source offset is committed only after DLQ publish.
- Contract test: CloudEvents envelope and payload schema match registry/AsyncAPI.
- Integration test: real broker via Testcontainers/LocalStack or the platform's local emulator.
- Replay test: consumer can restart from earliest offset without violating invariants.
