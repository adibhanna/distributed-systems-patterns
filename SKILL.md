---
name: distributed-systems-patterns
description: Apply distributed-systems, messaging, and integration patterns when designing, writing, or reviewing event-driven, microservice, queue, broker, saga, outbox, CDC, workflow, scaling, resilience, multi-region, or architecture-decision code and docs. Triggers include Kafka, RabbitMQ, SQS/SNS/EventBridge, Pub/Sub, Service Bus, NATS, Pulsar, Temporal, Step Functions, Camunda, Debezium, CloudEvents, AsyncAPI, OpenTelemetry, KEDA, and service mesh, plus concepts like idempotency, DLQs, retries, ordering, schema evolution, replay, fan-out, sharding, backpressure, circuit breaking, autoscaling, SLOs, RFCs, and ADRs. Generated code defaults to production-oriented Go.
---

# Distributed Systems Patterns

## Purpose

Use this skill for code, architecture, and decision documents that cross service boundaries. It covers distributed systems, integration, event-driven architecture, workflows, resilience, scaling, cloud/platform design, operations, security, and enterprise governance. The scope is any boundary crossing a process, machine, region, team, data owner, or reliability domain.

The patterns are technology-neutral; Kafka topics, SQS queues, Temporal workflows, EventBridge rules, Kubernetes autoscalers, Envoy circuit breakers, Debezium outbox SMTs, CloudEvents envelopes, and AsyncAPI contracts are modern implementations of the same pattern-and-forces mindset.

This skill is an operating procedure. For depth, load only the reference file needed:

- `reference/catalog.md` - systems, messaging, workflow, and resilience patterns with modern realizations.
- `reference/decision-tree.md` - problem-to-pattern selection guide.
- `reference/checklist.md` - review gates for producer, consumer, workflow, schema, security, infra, and tests.
- `reference/agent-workflow.md` - task lifecycle, output templates, and review behavior.
- `reference/architecture-documentation.md` - architecture docs, RFCs, ADRs, implementation plans, diagrams, and review rubrics.
- `reference/architecture-examples.md` - filled ADR/RFC examples for common decisions.
- `reference/distributed-systems-guide.md` - service boundaries, scaling, resilience, caching, sharding, multi-region, mesh, SLOs, and governance.
- `reference/modern-integration-field-guide.md` - modern EDA guidance, platform traps, replay, CQRS, and exactly-once boundaries.
- `reference/aws-service-mapping.md` - AWS-neutral mapping for SQS, SNS, EventBridge, Lambda, Kinesis, MSK, DynamoDB Streams, Step Functions, and S3.
- `reference/platform-service-mapping.md` - GCP, Azure, Kafka, RabbitMQ, NATS, Pulsar, and cloud-neutral mapping.
- `reference/scenario-playbooks.md` - common end-to-end architectures users can adapt.
- `reference/failure-modes.md` - failure catalog for reviews, incidents, and design docs.
- `reference/testing-strategy.md` - contract, integration, replay, workflow, failure, and load tests.
- `reference/security-compliance.md` - PII, secrets, tenant isolation, webhooks, IAM/ACLs, retention, and audit.
- `reference/operational-runbooks.md` - DLQ, lag, replay, schema rollback, workflow, and region failover runbooks.
- `reference/maturity-model.md` - adoption levels and next steps for teams/platforms.
- `reference/evaluation-prompts.md` - prompts to test whether the skill behaves well.
- `reference/go-examples.md` - production-oriented Go snippets.
- `reference/go-implementation-patterns.md` - Go worker pools, timeouts, idempotency interfaces, shutdown, and workflow reminders.
- `reference/production-guide.md` - enterprise defaults, ownership, SLOs, runbooks, and platform choices.
- `reference/message-contract-template.md` - CloudEvents + AsyncAPI contract starter.
- `reference/webhook-security-go.md` - webhook signature verification, timestamp windows, replay-window dedup, Go example.
- `reference/schema-migration.md` - concrete walkthrough for adding/renaming/removing event-contract fields without breaking consumers.
- `reference/cost-and-finops.md` - cost-aware operation: retention, per-event pricing, cross-region egress, queue depth vs spend.
- `reference/grpc-streaming.md` - gRPC server-streaming, bidirectional streams, deadlines, retry interceptors, status codes.
- `reference/llm-workflow-patterns.md` - async LLM inference queueing, bounded retry, model-output validation, streaming token handoff.
- `reference/non-go-pointers.md` - minimal pointers for Java/Spring Cloud Stream, TypeScript/NestJS, Python/FastAPI consumers.

## Mandatory Agent Contract

When this skill activates, every answer must include or perform these steps:

1. Name the integration, distributed-systems, and architecture pattern(s) in play.
2. Run the 8-question reliability checklist before writing or accepting code.
3. Flag anti-patterns directly, especially dual-write, missing idempotency, unbounded retries, and missing DLQ ownership.
4. Cite the modern tool or protocol that realizes the pattern.
5. When generating code, prefer Go unless the repo is clearly in another language.
6. Annotate produced integration code with pattern comments at the boundary - the producer call, consumer handler, retry/DLQ branch, idempotency check, or transaction boundary - for example `// Pattern: Idempotent Receiver - dedupe by CloudEvents id`. Do not repeat the same annotation on every line; the goal is to make the pattern visible at the point it is enforced, not to drown the code in comments.
7. Map readiness to the tier defined in `reference/production-guide.md` (Prototype → Service-ready → Production-ready → Enterprise-critical). Do not call code "production-ready" or "enterprise-critical" while reliability or distributed-systems checklist items are unanswered; downgrade to "service-ready" or "prototype" as appropriate and state the gaps.
8. If AWS services are in scope, load `reference/aws-service-mapping.md` and map the pattern to the AWS service without making the design AWS-only.
9. If the risk is scale, consistency, resilience, service boundaries, multi-region, or enterprise operations, load `reference/distributed-systems-guide.md` and name the distributed-systems pattern(s), not only the messaging pattern(s).
10. If the user asks for an architecture doc, design doc, RFC, ADR, technical plan, migration plan, or decision reference, load `reference/architecture-documentation.md` and produce a decision-ready document with patterns, alternatives, trade-offs, rollout, verification, and operations.
11. For production-readiness, launch, incident, security, or testing requests, load the specific guide: `security-compliance.md`, `testing-strategy.md`, `operational-runbooks.md`, `failure-modes.md`, or `maturity-model.md`.
12. **Write deliverable artifacts to files on disk, not just to chat.** When the response is a design doc, ADR, RFC, implementation plan, message contract, runbook, launch decision, or any structured multi-section document the user is likely to keep, write it under `docs/` (or the repo's existing convention) using a stable path: `docs/designs/<slug>-design.md`, `docs/adr/NNNN-<slug>.md`, `docs/architecture/<slug>-<doctype>.md`, `docs/contracts/<channel>.md`, `schemas/<channel>.<ext>`, `asyncapi/<channel>.yaml`, `docs/runbooks/<slug>.md`, or `docs/launches/<slug>-<YYYY-MM-DD>.md`. After writing, emit a one-line confirmation naming the path - do not paste the full document back into chat. Skip the file write only on an explicit opt-out signal: `show in chat only`, `don't write a file`, `chat only`, or `no file`. The bare verb "show" or phrases like "show me X before Y" are about response *ordering*, not output medium, and must not trigger the escape hatch. Conversational analyses (review findings, readiness assessment, failure-mode discussion) stay in chat by default.

13. **Design docs are decision artifacts, not code artifacts.** A design doc captures patterns chosen, boundary contracts at the conceptual level (channel names, ordering keys, idempotency keys, retention, DLQ owner, compatibility mode), file/component inventory, alternatives, open questions, and readiness tier. Implementation code belongs in source files, not in the design doc. Schema files belong in `schemas/` and `asyncapi/` produced by `/contract`. Runbooks belong in `docs/runbooks/`. If the user wants code after the design lands, treat that as a follow-up step.

Recommended response shape:

```text
Patterns: Event Message + Publish-Subscribe Channel + Idempotent Receiver
Reliability: at-least-once, dedupe by event.id in Redis, DLQ owned by inventory...
Anti-patterns: current code has db-save-then-publish dual-write
Modern realization: Postgres outbox + Debezium -> Kafka, CloudEvents, AsyncAPI, OpenTelemetry
Implementation: ...
Verification: ...
```

## When To Use

Trigger on any of these signals.

**Technology signals:** Kafka, RabbitMQ, SQS, SNS, EventBridge, Pub/Sub, Service Bus, Event Grid, NATS, MQTT, Redis Streams, ActiveMQ, Solace, Pulsar, Redpanda, Sidekiq, BullMQ, Celery, Temporal, Step Functions, Camunda, Debezium, Kafka Connect, Schema Registry, AsyncAPI, CloudEvents, OpenTelemetry, Kubernetes, KEDA, Envoy, Istio, Linkerd, Dapr, Consul, etcd, ZooKeeper (Kafka uses KRaft for new clusters; ZooKeeper still appropriate for non-Kafka coordination), Redis, CDN, API gateway.

**Concept signals:** queue, topic, channel, exchange, broker, event, command, message, async, pub/sub, fan-out, saga, process manager, workflow, orchestration, choreography, outbox, inbox, CDC, idempotency, DLQ, retry, dead-letter, replay, event-driven, event sourcing, CQRS, webhook, backpressure, partition, offset, consumer group, schema evolution, correlation id, distributed system, microservice, service boundary, bounded context, consistency, cache, shard, replica, rate limit, circuit breaker, bulkhead, load shedding, autoscaling, multi-region, tenant isolation, SLO, architecture document, design doc, RFC, ADR, implementation plan, migration plan.

**Code-shape signals:** message producer or consumer, webhook handler, Lambda event source, `@KafkaListener`, `pubsub.Subscribe`, `app.event(...)`, `@MessagePattern`, AsyncAPI file, `events/*.proto`, `*.avsc`, retry/DLQ config, partition key logic, cross-service write, Kubernetes HPA/KEDA manifests, Helm/Terraform service config, service mesh traffic policy, rate limiter, cache/shard code.

**Review signals:** PRs or diffs that publish, consume, route, transform, retry, dead-letter, replay, or version messages.

**Documentation signals:** User asks to create an architecture reference, design proposal, RFC, ADR, technical spec, implementation plan, migration plan, production-readiness review, or decision document for the system being built.

Do not use for pure local request-response, pure frontend work, single-process job queues with no service boundary, or ETL/batch pipelines that do not coordinate services or distributed reliability domains.

## Process

### 1. Pick the integration style

Confirm messaging is the right style before reaching for a broker.

| Style                       | Use when                                                                                       | Avoid when                                                                                |
| --------------------------- | ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| File Transfer               | Partner feeds, archival, bulk ingest, lakehouse handoff                                        | Sub-minute user workflows or transactional consistency                                    |
| Shared Database             | Single-team monoliths, analytics/OLAP, governed read-only reporting                            | OLTP writes across separately owned services                                              |
| Remote Procedure Invocation | Synchronous reads or commands where caller should fail if callee fails                         | Multi-step writes, fan-out, slow partners, workflows with compensation                    |
| Messaging                   | Async writes, fan-out, spike absorption, offline consumers, decoupling in time/location/format | User must read the downstream result immediately and cannot tolerate eventual consistency |

Default for cross-service writes: messaging plus explicit reliability answers. If the business flow spans multiple writes, add a Process Manager.

### 2. Name the pattern

Use this excerpt first, then load `reference/catalog.md` for fuller guidance.

| Need                          | Pattern                                                 | Modern realization                                                  |
| ----------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------- |
| Send work to one of N workers | Point-to-Point Channel + Competing Consumers            | Kafka consumer group; SQS queue; RabbitMQ queue                     |
| Broadcast to many consumers   | Publish-Subscribe Channel                               | Kafka topic with multiple groups; SNS; Pub/Sub; EventBridge         |
| One event type per channel    | Datatype Channel                                        | `orders.placed.v1`; AsyncAPI channel; Schema Registry subject       |
| Atomic DB write + publish     | Transactional Client via Outbox + CDC                   | Postgres outbox + Debezium -> Kafka; DynamoDB Streams               |
| Survive duplicate delivery    | Idempotent Receiver                                     | DB unique key; Redis `SETNX`; DynamoDB conditional put              |
| Bad messages                  | Invalid Message Channel + Dead Letter Channel           | Kafka DLT; SQS DLQ/redrive; RabbitMQ DLX; Pub/Sub dead-letter topic |
| Bounded failure recovery      | Retry + Dead Letter Channel                             | Exponential backoff, jitter, max attempts, owner/runbook            |
| Long-running business flow    | Process Manager (Saga)                                  | Temporal; Step Functions; Camunda 8; Azure Durable Functions        |
| Request/reply over async      | Request-Reply + Return Address + Correlation Identifier | NATS request/reply; RabbitMQ RPC; Kafka reply topic                 |
| Route by message content      | Content-Based Router                                    | EventBridge rules; SNS filters; Camel `choice()`                    |
| Transform schema/format       | Message Translator                                      | Kafka Streams; Flink; Schema Registry transforms; Camel             |
| Hide large payload            | Claim Check                                             | S3/GCS/Azure Blob object + `{uri, etag, sha256}` message            |
| Trace through hops            | Message History                                         | OpenTelemetry W3C Trace Context (`traceparent`)                     |
| Contract event APIs           | Canonical Data Model + Message Bus                      | CloudEvents, AsyncAPI 3.x, Avro/Protobuf/JSON Schema registry       |
| Reprocess history             | Message Store + Wire Tap                                | Kafka retention/compaction; EventBridge Archive; object-store sink  |
| Build on AWS                  | Pattern first, AWS realization second                   | SQS/SNS/EventBridge/Lambda/Kinesis/MSK/DynamoDB Streams/Step Functions |
| Prevent cascading failure     | Circuit Breaker + Bulkhead + Timeout                    | Envoy/Istio/Linkerd; Dapr resiliency; Go resilience libraries       |
| Survive overload              | Backpressure + Load Shedding + Rate Limiting            | Token bucket; API gateway quota; bounded queues; retry budgets      |
| Scale services by demand      | Horizontal Autoscaling + Queue-Based Scaling            | Kubernetes HPA; KEDA; Lambda concurrency                            |
| Scale data                    | Sharding + Replication + Materialized Views             | DynamoDB/Cassandra/Citus/Vitess; CDC; CQRS read models              |
| Reduce read latency           | Cache-Aside + Read Replica + CDN                        | Redis/Memcached; RDS replicas; CloudFront/Fastly                    |
| Coordinate exclusive work     | Lease + Fencing Token                                   | etcd/Consul/ZooKeeper; DynamoDB conditional writes                  |
| Release safely                | Progressive Delivery                                    | Canary, blue/green, feature flags, Argo Rollouts, Flagger           |

### 3. Run the 8-question reliability checklist

Answer these before writing or approving integration code:

1. **Delivery guarantee?** At-most-once, at-least-once, or effectively-once. Default to at-least-once plus Idempotent Receiver.
2. **Idempotency strategy?** Key plus store: CloudEvents `id`, business id, or idempotency key in DB unique index, Redis `SETNX` TTL, or DynamoDB conditional put.
3. **Bad-message strategy?** Invalid-message path and DLQ, with owner, alert, dashboard, runbook, retention, and redrive policy.
4. **Retry policy?** Bounded attempts, exponential backoff, jitter, transient/permanent classification, downstream timeout, and circuit breaker where useful.
5. **Ordering requirement?** Total, per-key, or none. Prefer per-key ordering by partition key, message group, session id, or subject.
6. **Schema evolution?** Avro, Protobuf, or JSON Schema with Registry/CI compatibility gate. For HTTP/webhooks, also publish AsyncAPI/OpenAPI as appropriate.
7. **Observability?** Propagate `traceparent`; emit lag, in-flight, processed, failed, retried, DLQ depth, age, and end-to-end latency.
8. **Failure boundary?** What rolls back, what compensates, what is replayed? Use Process Manager and explicit compensations for multi-step flows.

If any answer is "later", stop and answer it now.

### 3b. Run the distributed systems checklist

When the task is about services, scale, resilience, or enterprise operations, also answer:

1. **Boundary and ownership?** Which service/team owns the data, API, SLO, and on-call path?
2. **Consistency model?** Strong, read-your-writes, causal, eventual, or best-effort? What stale-read behavior is acceptable?
3. **Scaling axis?** Replicas, partitions/shards, tenants, regions, async buffering, cache/CDN, or read replicas?
4. **Failure mode?** Timeouts, retry storms, slow dependencies, partial outages, deploy rollback, and region loss.
5. **Backpressure?** Where are queues bounded, requests rejected, rate limits enforced, and overload signaled?
6. **Operations?** SLOs, dashboards, alerts, runbooks, capacity plan, security boundary, tenant isolation, and cost controls.

### 4. Apply enterprise defaults

- **Envelope:** Prefer CloudEvents 1.0 fields: `id`, `source`, `type`, `subject`, `time`, `specversion`, `datacontenttype`, `data`, plus extensions for `traceparent`, `correlationid`, `causationid`, `partitionkey`, and `expirytime`.
- **Channel names:** Semantic, versioned, and per event type: `orders.placed.v1`, not `events`.
- **Contracts:** AsyncAPI channels/operations plus schema files in repo. Compatibility check in CI.
- **Consistency:** Outbox for DB write + publish. Inbox/dedup table for consuming side effects. Avoid distributed 2PC across services.
- **Security:** No secrets in messages; tag PII in schema; encrypt in transit and at rest; least-privilege producer/consumer credentials; signed webhooks crossing trust boundaries.
- **Operations:** Every topic/queue has an owner, SLO, retention, replay policy, DLQ policy, dashboard, alert, and runbook.
- **Kafka cluster mode:** new clusters use KRaft (KIP-500); ZooKeeper is removed in Kafka 4.0. KIP-848 changes consumer rebalance - verify client support.
- **AWS mapping:** Use SQS for point-to-point work, SNS/EventBridge for fan-out/routing, Kinesis/MSK for streams/replay, DynamoDB Streams for CDC, Step Functions for Process Manager, S3 for Claim Check, and Lambda event source mappings as Message Endpoints. Preserve idempotency, DLQ ownership, trace propagation, and contract governance.
- **Go production style:** Use `context.Context`, typed structs, small interfaces, structured `log/slog`, OpenTelemetry propagation, bounded goroutines, graceful shutdown, and table-driven tests.

### 5. Generate code with pattern comments

Prefer Go snippets that expose failure modes. Keep helper abstractions thin enough that retries, DLQ, idempotency, ack/commit, and tracing remain visible.

```go
// Pattern: Transactional Outbox - persist domain state and event in one DB transaction.
func PlaceOrder(ctx context.Context, tx pgx.Tx, order Order) error {
	event := cloudevents.NewEvent()
	event.SetID(uuid.NewString())                       // Pattern: Correlation Identifier / dedupe key.
	event.SetSource("orders-service")
	event.SetType("com.acme.orders.placed.v1")          // Pattern: Datatype Channel.
	event.SetSubject(order.ID)                          // Pattern: per-key ordering candidate.
	event.SetTime(time.Now().UTC())
	if err := event.SetData(cloudevents.ApplicationJSON, OrderPlaced{OrderID: order.ID}); err != nil {
		return err
	}

	headers := propagation.MapCarrier{}
	otel.GetTextMapPropagator().Inject(ctx, headers)   // Pattern: Message History via trace context.

	payload, err := json.Marshal(event)
	if err != nil {
		return err
	}
	_, err = tx.Exec(ctx, `
		insert into outbox_events (id, aggregate_id, event_type, payload, headers, created_at)
		values ($1, $2, $3, $4, $5, now())`,
		event.ID(), order.ID, event.Type(), payload, map[string]string(headers),
	)
	return err
}
```

For complete producer, consumer, retry/DLQ, and Temporal Process Manager examples, load `reference/go-examples.md`.

### 6. Produce architecture documents when requested

When producing design docs, use `reference/architecture-documentation.md`. A decision-ready document must include:

- Goals and non-goals.
- Requirements and SLOs.
- Proposed architecture and ownership boundaries.
- Pattern mapping table.
- Data/contracts and message/request flows.
- Consistency, scaling, resilience, observability, security, and operations.
- Alternatives considered.
- Rollout/migration/rollback.
- Tests and verification.
- Risks, open questions, and decisions needed.

## Anti-Patterns To Flag

- `db.Save(); broker.Publish()` or `await db.commit(); await kafka.send()` - dual-write; use Outbox + CDC or a transactional producer when the whole boundary is Kafka.
- At-least-once delivery with a non-idempotent state mutation.
- Auto-commit/ack before processing and state commit.
- Unbounded retries, no jitter, or retrying permanent validation errors.
- DLQ with no owner, alert, dashboard, retention, or redrive procedure.
- One topic/queue carrying many unrelated event types.
- Distributed 2PC/XA across services.
- Synchronous RPC chain of three or more services for a write path.
- Shared OLTP database between separately owned services.
- Business rules hidden in routers/translators.
- Broker payloads near or above the platform's practical limit; use Claim Check before messages become operationally expensive.
- Missing correlation id, causation id, or `traceparent`.
- Schema changes merged without compatibility checks and consumer audit.
- "Eventually consistent" used to skip a Process Manager, Aggregator, timeout, or compensation.
- Distributed monolith: services cannot deploy independently.
- Retry storm: clients, mesh, broker, and SDK all retry without one shared budget.
- Unbounded queues, goroutines, connection pools, broker prefetch, or in-memory buffers.
- Cache treated as source of truth without durability, invalidation, or rebuild plan.
- Autoscaling on CPU while the real bottleneck is DB locks, queue age, shard hot spot, or downstream quota.
- Multi-region active-active with no conflict policy, failover runbook, or data residency answer.
- Distributed locks without leases, fencing tokens, and expiry handling.

## Verification Gate

Before accepting integration code, run `reference/checklist.md`. Minimum pass:

- Producer: no dual-write, stable id, schema/version, semantic channel, trace context, claim check if needed.
- Consumer: idempotent, bounded retry, DLQ wired/owned, ack after commit, trace/metrics/logs, graceful shutdown.
- Workflow: explicit Process Manager, per-step timeout, compensation, replayability, idempotent activities.
- Distributed systems: boundary owner, consistency model, scaling axis, backpressure, resilience policy, SLOs, runbook, and capacity plan.
- Architecture docs: goals, requirements, diagrams/flows, pattern mapping, alternatives, rollout, verification, risks, and open decisions.
- Schema: backward compatible, CI gate, versioned deprecation, consumer audit.
- Security/ops: credentials/ACLs, PII policy, dashboard/alert/runbook, replay/redrive procedure.
- Tests: unit mapper/gateway tests, dedup property test, contract test, real broker integration test, poison-message DLQ test.

For deeper verification, load `reference/testing-strategy.md`, `reference/failure-modes.md`, and `reference/operational-runbooks.md`.

## Scope

This is a practical pattern language and agent workflow for modern production systems: Kafka, RabbitMQ, SQS/SNS/EventBridge, Pub/Sub, NATS, Debezium, CloudEvents, AsyncAPI, Schema Registry, OpenTelemetry, Temporal, Step Functions, Camunda, Kubernetes, KEDA, Envoy/service mesh resilience, caching, sharding, multi-region, and enterprise operations.
