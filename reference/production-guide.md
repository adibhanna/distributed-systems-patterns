# Enterprise Production Guide

Use this guide when the task asks for production readiness, enterprise readiness, architecture review, platform choice, or launch review for messaging systems.

## Default architecture

For cross-service writes, the default enterprise shape is:

1. API/service writes its own database and an outbox row in one transaction.
2. Debezium, database stream, or a controlled outbox publisher emits a CloudEvents message to a semantic channel such as `orders.placed.v1`.
3. Consumers run as Idempotent Receivers with bounded retry and DLQ.
4. Long-running business outcomes are owned by a Process Manager such as Temporal, Step Functions, or Camunda.
5. Contracts live in AsyncAPI plus schema registry, and compatibility is checked in CI.
6. OpenTelemetry trace context is injected/extracted on every broker hop.

## Platform choice

| Platform                            | Strong fit                                                                      | Watch-outs                                                                               |
| ----------------------------------- | ------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Kafka / Redpanda                    | High-throughput event streams, replay, many consumer groups, ordered partitions | Requires partition design, retention/cost management, schema discipline                  |
| SQS + SNS                           | Simple queueing and AWS-native fan-out, operationally low overhead              | Standard queues are at-least-once and best-effort order; FIFO has throughput constraints |
| EventBridge                         | SaaS/AWS integration, cross-account routing, archive/replay, content rules      | Higher latency/cost than raw queues; schema discipline still needed                      |
| Kinesis Data Streams                | AWS-native ordered streams, retention, high-throughput ingestion                | Hot partition keys, shard math, checkpointing, replay-safe consumers                     |
| Amazon MSK                          | Kafka ecosystem on AWS, replay, stream processing, many consumer groups         | Kafka operational model still applies; external side effects still need idempotency      |
| RabbitMQ                            | Work queues, routing exchanges, request/reply, lower-latency command processing | Clustering/partition behavior and queue design need care at scale                        |
| Pub/Sub                             | GCP-native durable pub/sub, push/pull consumers, global service                 | Ordering keys and exactly-once options need explicit design                              |
| NATS JetStream                      | Low-latency messaging, request/reply, edge/service mesh patterns                | Persistence/retention model differs from Kafka; validate operational maturity            |
| Apache Pulsar                       | Multi-tenant streams, geo-replication, separate compute/storage                 | Operational complexity; client/team experience matters                                   |
| Temporal / Step Functions / Camunda | Durable workflow, timeouts, retries, compensation, visibility                   | Not a general event bus; Activities still need idempotency and contracts                 |

Do not choose a broker before the delivery, ordering, replay, latency, data residency, team ownership, and cost requirements are known.

For AWS-specific mapping, load `reference/aws-service-mapping.md`.
For broader service scaling and distributed systems design, load `reference/distributed-systems-guide.md`.

## Ownership contract

Every channel must have:

- Owner team and escalation path.
- Purpose and pattern names.
- Producer(s) and consumer(s).
- Schema location and compatibility mode.
- Delivery guarantee and ordering guarantee.
- Retention, replay, and redrive rules.
- DLQ name, owner, dashboard, alert, and runbook.
- PII classification and encryption requirements.
- SLOs and on-call playbook.

If no team owns a channel, no team owns the outage.

## Recommended SLOs and metrics

Define SLOs per workflow, not only per broker.

- End-to-end event latency: producer commit to consumer side effect.
- Queue age or consumer lag: oldest unprocessed message age is usually more actionable than count.
- DLQ depth and DLQ age: alert on first message for critical paths.
- Retry rate: alert on sustained deviation from baseline.
- Poison message rate: malformed/permanent failures per channel.
- Consumer throughput and saturation: in-flight, worker concurrency, downstream timeout rate.
- Broker health: disk, partitions, under-replicated partitions, publish error rate.
- Workflow health: stuck workflows, compensation count, timeout count, activity failure rate.
- Distributed systems health: saturation, rate limits, circuit breaker opens, cache hit ratio, shard hot spots, tenant throttles, regional failover status.

## Runbooks

Each DLQ/runbook should answer:

1. Who is paged?
2. How do I inspect one failed message safely?
3. How do I determine transient vs permanent failure?
4. How do I patch or quarantine bad messages?
5. How do I redrive at a controlled rate?
6. How do I verify downstream consumers are not overwhelmed?
7. How do I stop redrive?
8. How long are DLQ messages retained?
9. What is the audit trail for manual intervention?

Never redrive a DLQ blindly. Fix the cause or add a filter before replay.

## Security and compliance

- Treat messages as persisted data, not temporary network packets.
- Put no secrets in message bodies, headers, traces, logs, or DLQs.
- Classify PII in schemas and mask/redact logs.
- Encrypt in transit and at rest; understand broker-managed keys vs customer-managed keys.
- Use per-service credentials and least-privilege topic/queue ACLs.
- Sign webhooks and partner messages; verify timestamp and replay window.
- Avoid sensitive baggage in OpenTelemetry context.
- Set retention according to legal, privacy, and replay needs.

## Schema and contract policy

- Prefer Avro or Protobuf for Kafka-like ecosystems with Schema Registry.
- Use JSON Schema where JSON interoperability is more important than binary compactness.
- Use CloudEvents for envelope standardization and AsyncAPI for event API documentation.
- Backward compatibility is mandatory; forward compatibility is usually required.
- Do not remove or rename fields without a deprecation window and consumer audit.
- For breaking changes, run `v1` and `v2` channels in parallel and retire `v1` with an owner-approved date.

## Go service standards

Generated Go integration code should include:

- `context.Context` on every I/O boundary.
- Explicit interfaces for broker, dedup store, clock, and domain side effects.
- `log/slog` structured fields: `message_id`, `correlation_id`, `trace_id`, `topic`, `partition`, `offset`, `attempt`.
- OpenTelemetry extraction/injection at broker boundaries.
- Bounded worker pools and graceful shutdown on SIGTERM.
- Ack/commit after durable state change or DLQ publish.
- Table-driven tests for retry classification and idempotency.
- Integration tests with local broker/emulator for at least one success and one poison-message path.

## Enterprise distributed systems standards

- Service catalog entry for every production service: owner, tier, SLO, dependencies, APIs/events, data classification.
- ADR for every new distributed boundary, data ownership split, multi-region strategy, or consistency trade-off.
- Capacity plan based on expected traffic, burst, dependency quotas, and queue age targets.
- Resilience policy: timeout, retry budget, circuit breaker, bulkhead, rate limit, and load shedding.
- Tenant isolation: quotas, noisy-neighbor protection, shard placement, and per-tenant observability.
- Progressive delivery: canary/blue-green/feature flag, abort metrics, rollback owner.
- Disaster recovery: RPO/RTO, backup/restore, regional failover/failback, game-day evidence.

## Production readiness levels

These tiers map onto the maturity-model levels in `reference/maturity-model.md` (per-service tiers vs. ordinal ladder - same evidence).

| Tier                | Maturity level | Meaning                            | Gate                                                                                   |
| ------------------- | -------------- | ---------------------------------- | -------------------------------------------------------------------------------------- |
| Prototype           | Maturity 0     | Pattern is named and code compiles | Reliability checklist answered in comments or design notes                             |
| Service-ready       | Maturity 1-2   | Safe for shared dev/staging        | Unit tests, idempotency, bounded retry, DLQ, basic metrics                             |
| Production-ready    | Maturity 3     | Safe for customer traffic          | Contract CI, real broker test, dashboard, alert, runbook, owner, replay/redrive tested |
| Enterprise-critical | Maturity 4     | Regulated or revenue-critical path | SLOs, audit trail, DR plan, capacity test, security review, compatibility governance   |

Do not describe code as production-ready below the production-ready gate.
