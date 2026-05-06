# Modern Integration Field Guide

Use this when the task needs judgment beyond the core catalog: event-driven architecture, cloud brokers, platform-specific delivery guarantees, event sourcing, CQRS, replay, or production operations.

## What modern practice adds

Modern systems add these constraints:

- **Cloud-native brokers are opinionated.** Kafka partitions, SQS visibility timeouts, Pub/Sub ack deadlines, RabbitMQ prefetch, NATS JetStream consumers, and EventBridge archives all change the implementation.
- **Exactly-once is scoped.** Treat every "exactly once" claim as scoped to a producer, queue feature, region, broker transaction, or read-process-write boundary. External side effects still need idempotency.
- **Events are APIs.** Event contracts need the same discipline as REST/gRPC APIs: versioning, ownership, compatibility checks, security review, and deprecation policy.
- **Replay is a feature and a risk.** Consumers must be replay-safe before retention/backfill/replay can be used safely.
- **Operations are part of the design.** DLQ, redrive, lag/age, alerting, retention, PII, and audit trails are not post-implementation chores.

## Event vocabulary

Use these distinctions in designs and reviews:

| Term | Meaning | Good examples | Red flags |
| --- | --- | --- | --- |
| Domain event | Internal fact from the domain model | `OrderPlaced`, `PaymentCaptured` inside one bounded context | Leaking private aggregate structure to other services |
| Integration event | Public fact intended for other systems | `com.acme.orders.placed.v1` | Changing without consumer audit |
| Command | Request for one receiver to do work | `ReserveInventory`, `ChargePayment` | Broadcast command with multiple services racing |
| Document message | Data transfer where receiver decides action | Customer profile snapshot | Receiver infers business transitions from full snapshot |
| Notification | Thin signal that data changed elsewhere | `CustomerChanged` with resource link | Forces every consumer to call back synchronously |

Default: publish integration events, not raw domain events. Treat commands as point-to-point and events as publish-subscribe.

## Outbox, inbox, and dedup

The modern consistency baseline is:

1. Producer writes domain state plus outbox row in one local transaction.
2. CDC/publisher emits the outbox row.
3. Consumer records an inbox/dedup entry before or with its side effect.
4. Consumer commits/acks only after the side effect and dedup state are durable.

Dedup store choices:

| Store | Use when | Watch-outs |
| --- | --- | --- |
| DB unique index | Consumer side effect is already in SQL | Cleanup/retention strategy needed |
| Inbox table | Need audit trail and replay diagnostics | Can grow fast; partition/archive |
| Redis `SETNX` TTL | High-throughput short dedup window | Lost dedup after TTL; Redis outage affects consumers |
| DynamoDB conditional put | AWS-native, high scale, TTL cleanup | Hot partition risk if key design is poor |
| Natural idempotency | State transition can be expressed as upsert/compare-and-set | Must prove duplicate is no-op under concurrency |

Ask: "How long can a duplicate arrive?" Set dedup TTL/retention to at least broker retention, replay window, and external retry window.

## Delivery guarantees: ask what boundary

| Claim | Usually means | Still required |
| --- | --- | --- |
| At-most-once | May lose messages, no retry after failure | Only acceptable for telemetry or disposable signals |
| At-least-once | No committed message should be lost, duplicates possible | Idempotent Receiver |
| Kafka idempotent producer | Producer retries do not duplicate records in the stream | Consumer idempotency for reprocessing |
| Kafka transactions | Atomic consume-process-produce inside Kafka transaction boundaries | Idempotency for external DB/API side effects |
| SQS FIFO exactly-once processing | FIFO queue avoids duplicate sends within dedup window | Idempotent consumer after visibility timeout/redrive/replay |
| Pub/Sub exactly-once | Pull subscription can avoid redelivery after successful ack in supported scope | Track progress until ack succeeds |
| NATS JetStream exactly-once scope | `Nats-Msg-Id` dedupe window plus double acknowledgements can confirm publish/ack success | Idempotent external side effects |
| Temporal workflow durability | Workflow history and retries are durable | Idempotent Activities and deterministic workflow code |

If a design says "exactly once" without naming the boundary, flag it.

## Ordering design

Prefer **per-key ordering**. Total order is rarely worth the throughput and availability cost.

Good keys:

- `order_id` for order lifecycle.
- `account_id` for account balance transitions.
- `customer_id` for customer profile updates.
- Aggregate id from the outbox table for Kafka partition key.

Bad keys:

- `tenant_id` for a large tenant: creates hot partitions/groups.
- Event type: destroys per-entity ordering.
- Timestamp: does not group related state changes.
- Random UUID when per-entity ordering is required.

Always ask:

1. Which entity needs ordering?
2. What happens if messages for different entities interleave?
3. What happens when one hot key falls behind?
4. Can the consumer process independent keys concurrently?
5. Does redelivery block subsequent messages for the same key?

## Event versioning

Version the public contract, not the implementation class.

- Add optional fields with defaults when possible.
- Do not rename fields in place; introduce a new field, dual-publish during the transition, migrate consumers, then deprecate. For renames that justify a new channel version, see `reference/schema-migration.md`.
- Do not change field meaning under the same name.
- Keep `v1` and `v2` channels side-by-side for breaking changes.
- Let consumers ignore unknown fields.
- Run compatibility checks in CI before producer changes merge.

Avoid "god envelope" fields like `event_type` in one shared `events` topic unless the broker/platform forces it. Prefer one event type per channel.

## Choreography vs orchestration

Use choreography when:

- The workflow is shallow.
- Each service can make progress independently.
- No one needs a single queryable workflow state.
- Compensations are simple or unnecessary.

Use a Process Manager when:

- The business process has timeouts, approvals, retries, or compensation.
- Product/support needs to query "where is this order?"
- Steps must be cancelled, paused, resumed, or escalated.
- Pure events create an implicit state machine across many handlers.

Good Process Managers emit commands and consume events. They should not own every service's data.

## Event sourcing and CQRS

Do not confuse an integration event stream with an event-sourced aggregate log.

Event sourcing requires:

- Events are the source of truth for aggregate state.
- Event schemas remain replayable forever or have upcasters.
- Aggregate invariants are enforced while appending events.
- Snapshots are optimization, not truth.

CQRS read models require:

- Rebuild plan from the event log.
- Versioned projections.
- Backfill/replay safety.
- Explicit lag and freshness SLOs.

Do not start with event sourcing just because the system uses Kafka.

## Retry taxonomy

Classify failures before retrying:

| Failure | Action |
| --- | --- |
| Timeout, 429, 503, network reset | Retry with bounded exponential backoff and jitter |
| Dependency outage | Retry, circuit-break, alert on sustained failure |
| Schema/deserialization error | Invalid Message Channel or DLQ immediately |
| Business validation failure | DLQ or rejected-event path; do not retry blindly |
| Authentication/authorization failure | Stop, alert owner, do not redrive until fixed |
| Rate limit | Backoff using server hint where available |

Permanent errors should not burn retry budget or block ordered keys.

## Replay, redrive, and backfill

Before replaying:

- Confirm consumers are idempotent and replay-safe.
- Freeze or version external side effects such as emails, payments, shipments.
- Redrive in small batches with a stop switch.
- Preserve original message id and trace/correlation context when replay semantics require dedup.
- Add a replay marker if consumers need to branch behavior.
- Measure downstream saturation during replay.

Never redrive the DLQ until the cause is fixed or filtered.

## Platform-specific traps

| Platform | Good use | Traps to check |
| --- | --- | --- |
| Kafka/Redpanda | Durable event streams, replay, many consumer groups | Hot partitions, schema drift, compaction tombstones, transactions only cover Kafka boundaries, consumer lag count without age |
| SQS Standard | Simple at-least-once work queue | Best-effort ordering, duplicates, visibility timeout too short, DLQ redrive overload |
| SQS FIFO | Ordered per message group, dedupe window | Throughput limits, hot message groups, dedup window is finite |
| SNS | Simple fan-out | Filtering policy drift, delivery retry behavior per subscription |
| EventBridge | SaaS/AWS routing, archive/replay | Cost/latency, rule sprawl, weak schema ownership if not governed |
| Pub/Sub | Managed fan-out and subscriptions | Ack deadline expiration, hot ordering keys, exactly-once only for supported pull scope |
| RabbitMQ | Low-latency work queues and routing | Missing publisher confirms, unbounded prefetch, classic vs quorum queue choice, DLX ownership |
| Azure Service Bus | Enterprise queues/topics, duplicate detection, sessions, DLQ | Duplicate detection is time-windowed; sessions require session-aware send/receive; DLQ has no automatic cleanup |
| NATS Core | Low-latency ephemeral messaging | At-most-once by default; no persistence/replay |
| NATS JetStream | Durable streams and replay with simple ops | Dedupe window, AckWait/MaxDeliver/backoff config, durable vs ephemeral consumers, stream retention policy |
| Temporal | Durable business workflows | Non-deterministic workflow code, non-idempotent Activities, treating it as a broker |
| Debezium Outbox | CDC-based outbox publishing | Updates/deletes in outbox table, missing aggregate key, connector lag, schema routing drift |

## Source-checked modern notes

These are the current operational interpretations to preserve when editing the skill:

- **AsyncAPI 3.1** is current and explicitly models channels, operations, messages, and protocol bindings. Use it for event API documentation, but do not assume sender and receiver specs are mechanically interchangeable.
- **CloudEvents v1.0.2** is the stable CloudEvents release line to reference; keep message `specversion` at `1.0` unless the ecosystem standard changes. Treat custom fields such as `correlationid`, `causationid`, `partitionkey`, and `expirytime` as extensions that must be documented.
- **Kafka** is best understood as a persistent, partitioned log. Partition keys control locality/order; consumer offsets are controllable and can be rewound. Transactions help inside Kafka read-process-write boundaries, not arbitrary external side effects.
- **Kafka modern shifts (2025-2026):** Kafka 4.0 ships KRaft as the only supported metadata mode (ZooKeeper is removed); new clusters should not deploy ZooKeeper. **KIP-848** (next-gen consumer rebalance protocol, default in 4.0) replaces the stop-the-world rebalance with an incremental cooperative protocol on the broker side; client support varies by Kafka protocol version; check your client's KIP-848 readiness before adopting Kafka 3.7+ rebalance protocol. **KIP-405** tiered storage (GA in OSS Kafka 3.6+, available in MSK and Confluent Cloud) decouples retention from broker disk, making long retention dramatically cheaper. For Go, several Kafka clients exist - `franz-go`, `kafka-go`, and `confluent-kafka-go` - with different trade-offs around protocol coverage (KRaft and KIP-848 support), maintenance status, and operational ergonomics. Pick based on team familiarity and the protocol versions you need; the patterns in this skill apply regardless of client.
- **RabbitMQ** reliable delivery depends on publisher confirms and manual consumer acknowledgements. Automatic acknowledgement is unsafe for workloads where processing must not be lost. Bound prefetch to avoid consumer memory blowups.
- **SQS FIFO** dedupe is finite-window producer-side protection. Standard queues remain at-least-once and best-effort order. Consumers still need idempotency.
- **Pub/Sub exactly-once** applies to supported pull subscriptions and has regional/acknowledgement constraints. Subscribers must track processing progress until acknowledgement succeeds.
- **Azure Service Bus duplicate detection** is based on application-controlled `MessageId` within a configured time window. Sessions provide FIFO-style ordered processing for related messages, and Service Bus DLQs retain messages until explicitly drained.
- **NATS JetStream** supports publish dedupe via `Nats-Msg-Id` within a dedupe window and double acknowledgements for consumer ack confirmation. External side effects still need idempotency.
- **KEDA** is appropriate when scaling should follow event-source metrics such as queue length, stream lag, or Prometheus metrics; HPA remains appropriate for CPU/memory/custom metric scaling.

## Design review prompts

Use these prompts when an agent is about to overfit to code:

- What is the integration style and why?
- Which message is a command, event, document, or notification?
- What is the one entity that needs ordering?
- What is the first duplicate the system will see in production?
- How does the DLQ get noticed, owned, fixed, and redriven?
- What exact boundary does "exactly once" apply to?
- Can this consumer replay a year of history without sending emails or charging cards twice?
- Which schema change would break the oldest known consumer?
- What happens if the broker is healthy but the downstream dependency is slow?
- How would support answer "where is order 123 right now?"

## Primary sources worth checking

- CloudEvents specification: https://github.com/cloudevents/spec/tree/ce%40v1.0.2/cloudevents
- AsyncAPI specification: https://www.asyncapi.com/docs/reference/specification/v3.1.0
- Kafka documentation: https://kafka.apache.org/documentation/
- Kafka KIP-848 (next-gen consumer rebalance protocol): https://cwiki.apache.org/confluence/display/KAFKA/KIP-848%3A+The+Next+Generation+of+the+Consumer+Rebalance+Protocol
- Kafka KIP-405 (tiered storage): https://cwiki.apache.org/confluence/display/KAFKA/KIP-405%3A+Kafka+Tiered+Storage
- RabbitMQ confirms and acknowledgements: https://www.rabbitmq.com/docs/confirms
- Azure Service Bus duplicate detection: https://learn.microsoft.com/en-us/azure/service-bus-messaging/duplicate-detection
- Azure Service Bus sessions: https://learn.microsoft.com/en-us/azure/service-bus-messaging/message-sessions
- AWS SQS FIFO exactly-once processing: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues-exactly-once-processing.html
- Google Pub/Sub ordering: https://cloud.google.com/pubsub/docs/ordering
- Google Pub/Sub exactly-once delivery: https://cloud.google.com/pubsub/docs/exactly-once-delivery
- NATS JetStream consumers: https://docs.nats.io/nats-concepts/jetstream/consumers
- Debezium Outbox Event Router: https://debezium.io/documentation/reference/stable/transformations/outbox-event-router.html
- OpenTelemetry Go instrumentation: https://opentelemetry.io/docs/languages/go/instrumentation/
- Temporal Go developer guide: https://docs.temporal.io/develop/go
