# Scenario Playbooks

Use this when a user asks "how should we build X?" and X resembles a common distributed system or event-driven workflow. Each playbook is a starting point, not a final architecture.

## Order fulfillment saga

**Use when:** checkout/order flow spans payment, inventory, shipping, notifications, or fraud.

**Patterns:** Event Message, Command Message, Process Manager, Transactional Outbox, Idempotent Receiver, Dead Letter Channel, Message History.

**Reference design:**

1. Orders API writes order + outbox event in one DB transaction.
2. CDC publishes `orders.placed.v1`.
3. Fulfillment Process Manager starts by `order_id`.
4. Process Manager sends commands: `ChargePayment`, `ReserveInventory`, `CreateShipment`.
5. Each activity is idempotent by workflow id + business id.
6. Each successful step registers compensation: refund payment, release inventory, cancel shipment.
7. Milestone events are published with CloudEvents and trace context.
8. DLQs are owned by the service that can fix the failure.

**Prime-time gates:** workflow replay test, compensation test, duplicate event test, stuck workflow dashboard, support query for "where is order X?"

## Webhook ingestion platform

**Use when:** third-party providers call your HTTP endpoint and retry delivery.

**Patterns:** Channel Adapter, Idempotent Receiver, Message Store, Invalid Message Channel, Dead Letter Channel, Smart Proxy, Wire Tap.

**Reference design:**

1. HTTP endpoint verifies signature, timestamp, and replay window.
2. Store raw request body and headers if compliance allows.
3. Dedupe by provider delivery id.
4. Convert provider payload to internal CloudEvents message.
5. Publish to semantic internal channel, for example `github.pull_request.opened.v1`.
6. Permanent validation/signature failures go to invalid-message path; transient internal failures retry.

**Prime-time gates:** signature tests, replay-window tests, duplicate delivery test, poison payload DLQ test, provider redelivery runbook.

## Multi-tenant SaaS event bus

**Use when:** many tenants produce/consume events through a shared platform.

**Patterns:** Message Bus, Datatype Channel, Canonical Data Model, Selective Consumer, Tenant Isolation, Quotas, Backpressure.

**Reference design:**

1. Use semantic event channels and tenant metadata.
2. Enforce tenant authN/authZ at publish and subscribe.
3. Apply per-tenant quotas and rate limits.
4. Partition by stable business key; do not let one tenant hot-spot the whole platform.
5. Expose AsyncAPI/schema catalog.
6. Track per-tenant lag, DLQ depth, retry rate, and cost.

**Prime-time gates:** noisy-neighbor test, tenant isolation test, schema compatibility CI, per-tenant observability.

## Audit/event lake pipeline

**Use when:** events need long-term audit, analytics, replay, or compliance storage.

**Patterns:** Wire Tap, Message Store, Claim Check, Content Filter, Message History.

**Reference design:**

1. Wire tap production event channels to object storage.
2. Redact or tokenize sensitive fields before long-term storage.
3. Partition by event type/date/tenant where appropriate.
4. Keep raw immutable events and curated analytics tables separate.
5. Document retention, legal hold, replay, and deletion constraints.

**Prime-time gates:** PII scan, retention policy, replay drill, cost estimate, audit access controls.

## High-volume ingestion pipeline

**Use when:** IoT, telemetry, clickstream, logs, or metrics are high-throughput.

**Patterns:** Publish-Subscribe Channel, Message Filter, Content-Based Router, Backpressure, Sharding/Partitioning, Message Store.

**Reference design:**

1. Use partitioned stream by device/account/customer key.
2. Validate and drop malformed disposable telemetry early.
3. Separate hot operational path from cold analytics path.
4. Use queue/stream lag age as the scaling signal.
5. Use object storage as durable replay/archive.

**Prime-time gates:** hot-key test, load test, retention/cost model, backpressure behavior, malformed-message policy.

## Payment workflow

**Use when:** money movement or authorization requires strict idempotency and audit.

**Patterns:** Process Manager, Command Message, Idempotent Receiver, Correlation Identifier, Message Store, Dead Letter Channel.

**Reference design:**

1. Payment commands carry idempotency key and correlation id.
2. Payment provider calls are wrapped by activities with explicit timeout/retry policy.
3. Store provider request/response audit safely with sensitive-field redaction.
4. Use compensation/refund only where the business and provider support it.
5. Publish public payment events after durable state changes.

**Prime-time gates:** duplicate charge test, provider timeout test, reconciliation process, audit trail, PCI/PII review.

## Broker migration

**Use when:** moving from RabbitMQ/JMS/SQS/etc. to Kafka/MSK/Pub/Sub/EventBridge.

**Patterns:** Messaging Bridge, Message Translator, Wire Tap, Datatype Channel, Idempotent Receiver.

**Reference design:**

1. Build bridge from old broker to new broker.
2. Preserve message id, correlation id, causation id, and ordering key when possible.
3. Translate old envelope to CloudEvents.
4. Run consumers in shadow mode.
5. Migrate consumers one at a time; producer last.
6. Keep rollback path until consumers are stable.

**Prime-time gates:** parity check, duplicate handling, rollback test, lag monitoring, consumer migration inventory.

## DLQ replay incident

**Use when:** messages accumulated in DLQ and need safe redrive.

**Patterns:** Dead Letter Channel, Message Store, Channel Purger, Control Bus, Idempotent Receiver.

**Reference design:**

1. Stop automatic redrive.
2. Classify messages by reason/error/event type.
3. Fix code/config/schema or filter unrecoverable messages.
4. Redrive a small sample at low rate.
5. Monitor downstream saturation, errors, and duplicate side effects.
6. Increase gradually with stop switch.

**Prime-time gates:** root cause identified, replay-safe consumers, redrive owner, audit trail, post-incident action items.
