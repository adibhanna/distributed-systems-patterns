# Production Review Checklist

Run these checks before merging integration code. Each item should be backed by evidence: code reference, test output, schema diff, dashboard, runbook, or platform config.

## Pattern framing

- [ ] Pattern names are stated in the design or PR: Event Message, Datatype Channel, Idempotent Receiver, Process Manager, etc.
- [ ] Distributed-systems patterns are named when relevant: Circuit Breaker, Bulkhead, Backpressure, Sharding, Cache-Aside, Lease/Fencing Token, Progressive Delivery, etc.
- [ ] Integration style is justified: File Transfer, Shared Database, Remote Procedure Invocation, or Messaging.
- [ ] Modern realization is identified: Kafka, SQS/SNS/EventBridge, Pub/Sub, RabbitMQ, NATS, Debezium, CloudEvents, AsyncAPI, Temporal, etc.
- [ ] The 8-question reliability checklist is fully answered; no "later" items.
- [ ] The distributed systems checklist is answered when the change affects scale, service boundaries, resilience, multi-region, or enterprise operations.
- [ ] Architecture docs/RFCs include pattern mapping, alternatives, rollout, verification, operations, risks, and open decisions.

## Producer

- [ ] **No dual-write.** DB write and event publish are handled by Outbox + CDC/publisher, or by broker transactions where the whole boundary supports them.
- [ ] **Stable message id.** UUIDv7 by default (sortable, time-prefixed); UUIDv4 or content hash when v7 is unavailable. Used for correlation and dedup.
- [ ] **Correlation and causation ids.** Propagated from inbound request or generated at the root.
- [ ] **CloudEvents or equivalent envelope.** Includes `id`, `source`, `type`, `subject`, `time`, `specversion`, `datacontenttype`.
- [ ] **Semantic Datatype Channel.** One event type per topic/queue/channel, for example `orders.placed.v1`.
- [ ] **Schema versioned and registered.** Avro, Protobuf, or JSON Schema with registry or checked-in schema version.
- [ ] **Format Indicator.** `contentType`, schema id, CloudEvents `specversion`, or equivalent header.
- [ ] **Trace context.** W3C `traceparent` injected into message headers/extensions.
- [ ] **Partition/order key.** Explicit when per-key ordering is required.
- [ ] **Claim Check.** Large payloads stored in object storage with `{uri, etag, sha256}` in the message.
- [ ] **Message Expiration/TTL.** Set for stale-sensitive data such as quotes, OTPs, offers, locks.
- [ ] **Producer retry safety.** Retries cannot create inconsistent state or duplicate business effects.

## Consumer

- [ ] **Idempotent Receiver.** Explicit dedup key and store: DB unique index, Redis `SETNX` TTL, DynamoDB conditional put, or inbox table.
- [ ] **Bounded retry.** Exponential backoff, jitter, max attempts, timeout, and transient/permanent classification.
- [ ] **Dead Letter Channel.** DLQ/DLT is wired, monitored, owned, retained, and has a redrive runbook.
- [ ] **Invalid Message Channel.** Deserialization/schema failures are separated from processing failures where the platform allows it.
- [ ] **Ack/commit after durable work.** Offset/message delete happens only after side effect succeeds or DLQ publish succeeds.
- [ ] **No auto-commit before processing.** Kafka `enable.auto.commit=false` or equivalent behavior.
- [ ] **Backpressure.** Bounded prefetch/poll buffers, bounded goroutines/workers, and downstream timeouts.
- [ ] **No payload switch for unrelated event types.** Use Datatype Channel, Message Dispatcher, or Selective Consumer.
- [ ] **Trace context extracted.** Consumer logs/spans join the producer trace when trusted.
- [ ] **Metrics emitted.** Lag/age, in-flight, processed, failed, retried, DLQ depth, processing latency.
- [ ] **Structured logs.** Include message id, correlation id, trace id, topic/queue, partition, offset, attempt.
- [ ] **Graceful shutdown.** Stops polling, drains in-flight work, commits completed messages, leaves unfinished work visible for redelivery.
- [ ] **Replay-friendly.** Re-reading old messages does not violate invariants.

## Workflow / Saga

- [ ] **Process Manager is explicit.** Temporal, Step Functions, Camunda, Durable Functions, or equivalent owns the state machine.
- [ ] **Commands and events are named.** Commands are imperative; events are past-tense immutable facts.
- [ ] **Each step has timeout and retry policy.** No infinite waits.
- [ ] **Each completed step has compensation** when business consistency requires undo.
- [ ] **Activities/steps are idempotent** with propagated workflow/business id.
- [ ] **Replayable history.** Workflow can recover from stored history without nondeterminism.
- [ ] **Versioning plan.** Long-running workflows survive activity signature and schema changes.
- [ ] **Visibility.** Stuck workflows, timeouts, compensations, and cancellations are queryable and alertable.

## Schema and contract

- [ ] **AsyncAPI or equivalent contract exists** for event APIs and channels.
- [ ] **Backward compatibility.** Old consumers can read new messages.
- [ ] **Forward compatibility.** New consumers can read old messages when required.
- [ ] **No removed/renamed fields** without deprecation window and consumer audit.
- [ ] **No incompatible type changes** on existing fields.
- [ ] **Defaults for new optional fields** where the schema format supports defaults.
- [ ] **CI compatibility gate.** Registry or schema check fails incompatible changes.
- [ ] **Version migration path.** Breaking changes use parallel `v1` + `v2` channels and a retirement date.

## Security and PII

- [ ] **No secrets in payload, headers, traces, logs, or DLQs.**
- [ ] **PII classified in schema** and redacted from logs.
- [ ] **Encryption in transit and at rest** meets platform/security requirements.
- [ ] **Least-privilege credentials.** Per-app producer/consumer identities and topic/queue ACLs.
- [ ] **Signed messages/webhooks** when crossing trust boundaries; timestamp/replay window validated.
- [ ] **Retention policy** satisfies privacy, legal, cost, and replay needs.
- [ ] **Webhook/event signatures** are verified before trust-boundary messages are accepted.
- [ ] **Replay/redrive permissions** are restricted and audited.
- [ ] **Tenant isolation** is enforced in auth, quotas, logs, metrics, and support tooling where multi-tenancy exists.

## Infrastructure and operations

- [ ] **Owner/runbook per channel.** Includes escalation, dashboard, replay/redrive, and purge procedure.
- [ ] **Durability config.** Kafka `acks=all`/replication or cloud-provider equivalent for non-lossy paths.
- [ ] **Partition/concurrency plan.** Partition count or queue concurrency matches throughput and ordering needs.
- [ ] **Retention explicit.** Long enough for replay; short enough for cost/privacy.
- [ ] **DLQ redrive tested.** Rate-limited redrive and stop procedure are known.
- [ ] **Capacity tested.** Producer spikes and slow-consumer scenarios do not OOM or exhaust broker storage.
- [ ] **Disaster recovery defined** for critical channels: RPO/RTO, cross-region bridge, replay source.

## Distributed systems and scale

- [ ] **Service boundary is owned.** Data owner, API owner, SLO, and on-call team are explicit.
- [ ] **Consistency model is named.** Strong/read-your-writes/causal/eventual/best-effort and acceptable staleness are documented.
- [ ] **Scaling axis is clear.** Replicas, shards, tenants, regions, queues, cache/CDN, or read replicas.
- [ ] **Timeouts and retry budgets** prevent retry storms and cascading failure.
- [ ] **Circuit breakers/bulkheads** protect critical dependencies and isolate traffic classes.
- [ ] **Backpressure/load shedding** is explicit: bounded queues, rate limits, 429/503 policy, and overload metrics.
- [ ] **Cache policy** includes TTL, invalidation, stampede protection, and stale-read tolerance.
- [ ] **Sharding/partitioning plan** includes hot-key analysis, resharding/migration plan, and tenant isolation.
- [ ] **Coordination primitives** use leases/fencing tokens where exclusive work is required.
- [ ] **Multi-region plan** names active-active/passive, RPO/RTO, failover/failback, conflict policy, and data residency.
- [ ] **Progressive delivery** has canary/blue-green/feature-flag strategy, abort thresholds, and rollback owner.
- [ ] **Enterprise governance** covers service catalog, ADRs, cost ownership, security boundaries, compliance, and deprecation policy.

## AWS implementation

Use this section only when AWS services are in scope. See `reference/aws-service-mapping.md`.

- [ ] **SQS visibility timeout** exceeds handler/downstream timeout, or the consumer extends visibility while processing.
- [ ] **SQS/Lambda partial batch response** is enabled when batch records can independently succeed or fail.
- [ ] **SQS FIFO message group id** matches the real per-key ordering requirement and avoids hot groups.
- [ ] **SNS/EventBridge targets** have DLQ/failure handling where delivery matters.
- [ ] **EventBridge archive/replay** is enabled only when consumers are replay-safe and redrive runbook exists.
- [ ] **Lambda stream consumers** define retry attempts, bisect-on-error/on-failure destination, and shard blocking behavior.
- [ ] **DynamoDB idempotency** uses conditional writes and TTL/inbox retention long enough for replay/retry windows.
- [ ] **Step Functions workflows** model retries, catches, timeouts, and compensations explicitly.
- [ ] **S3 Claim Check** messages include bucket/key/version or etag/checksum/size and lifecycle/security policy.
- [ ] **IAM least privilege** exists per producer, consumer, workflow, and redrive/operator role.

## Go implementation

- [ ] `context.Context` is passed through every I/O boundary.
- [ ] Integration code uses typed structs, small interfaces, and table-driven tests.
- [ ] `log/slog` or the repo-standard structured logger includes message/correlation/trace fields.
- [ ] OpenTelemetry propagator is configured and used with broker headers.
- [ ] Goroutines, worker pools, and retries are bounded.
- [ ] Shutdown handles SIGTERM and does not drop in-flight messages.
- [ ] Time/randomness in Temporal workflows is deterministic (`workflow.Now`, workflow APIs, Activities for side effects).

## Test coverage

- [ ] **Unit:** mapper/gateway/envelope code covered without a real broker.
- [ ] **Idempotency:** same message twice produces the side effect once.
- [ ] **Retry:** transient errors retry with bounded backoff; permanent errors do not loop.
- [ ] **DLQ:** malformed or poison message reaches DLQ and source is committed only after DLQ publish.
- [ ] **Contract:** producer and consumer schemas are checked against registry/AsyncAPI.
- [ ] **Integration:** real broker/emulator covers one happy path and one failure path.
- [ ] **Replay:** consumer restart from earliest offset or replay source is safe.
- [ ] **Workflow:** Process Manager success, failure, compensation, timeout, and replay behavior tested.
- [ ] **Security:** sensitive fields are redacted from logs/DLQ/traces and access controls are tested.
- [ ] **Operational drill:** DLQ redrive/replay or failover runbook tested for critical paths.
