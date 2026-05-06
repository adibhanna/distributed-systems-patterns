---
name: distributed-systems-patterns
description: Apply distributed-systems, messaging, and integration patterns to architectural decisions, message contracts, and operational artifacts for event-driven, microservice, queue, broker, saga, outbox, CDC, workflow, scaling, resilience, and multi-region work. Triggers include Kafka, RabbitMQ, SQS/SNS/EventBridge, Pub/Sub, Service Bus, NATS, Pulsar, Temporal, Step Functions, Debezium, CloudEvents, AsyncAPI, OpenTelemetry, KEDA, and service mesh, plus idempotency, DLQs, retries, ordering, schema evolution, replay, sharding, backpressure, circuit breaking, autoscaling, SLOs, RFCs, and ADRs. Default outputs are decisions and contracts, not implementation code; specific libraries are user choices.
version: 0.2.0
tags: [distributed-systems, messaging, event-driven, integration, architecture, microservices, kafka, aws, cloudevents, asyncapi]
---

# Distributed Systems Patterns

## Purpose

This skill is a **connected system for designing distributed systems at scale**. It produces decisions, contracts, runbooks, and operational artifacts that link together into a per-service index and a system-level catalog, so a reader can navigate from "the system" down to a specific channel's runbook in two clicks.

Scope covers integration, messaging, event-driven architecture, workflows, resilience, scaling, and cloud/platform design **plus the layer beyond code**: team ownership and Conway's Law boundaries, multi-tenancy, cost ownership, compliance (PII, GDPR, SOC2, data residency), capacity planning, disaster recovery, lifecycle (deprecation, migration, retirement), and governance. Default outputs are architectural and operational artifacts, not implementation code.

The skill is technology-neutral. Kafka topics, SQS queues, Temporal workflows, EventBridge rules, Kubernetes autoscalers, Envoy circuit breakers, Debezium outbox SMTs, CloudEvents envelopes, and AsyncAPI contracts are modern implementations of the same pattern-and-forces mindset. Specific package picks (which Kafka client, which ORM) are team decisions; the skill recommends categories and lists options with trade-offs.

This skill is an operating procedure. Load only the reference file needed:

**Architectural and decision references** (load when designing, reviewing, or documenting):
- `reference/catalog.md` - systems, messaging, workflow, and resilience patterns with modern realizations.
- `reference/decision-tree.md` - problem-to-pattern selection guide.
- `reference/checklist.md` - review gates for producer, consumer, workflow, schema, security, infra, and tests.
- `reference/agent-workflow.md` - task lifecycle, output templates, and review behavior.
- `reference/architecture-documentation.md` - architecture docs, RFCs, ADRs, implementation plans, diagrams, and review rubrics.
- `reference/architecture-examples.md` - filled ADR/RFC examples for common decisions.
- `reference/distributed-systems-guide.md` - service boundaries, scaling, resilience, caching, sharding, multi-region, mesh, SLOs, and governance.
- `reference/modern-integration-field-guide.md` - modern EDA guidance, platform traps, replay, CQRS, and exactly-once boundaries.
- `reference/scenario-playbooks.md` - common end-to-end architectures users can adapt.
- `reference/failure-modes.md` - failure catalog for reviews, incidents, and design docs.
- `reference/testing-strategy.md` - contract, integration, replay, workflow, failure, and load tests.
- `reference/security-compliance.md` - PII, secrets, tenant isolation, webhooks, IAM/ACLs, retention, and audit.
- `reference/operational-runbooks.md` - DLQ, lag, replay, schema rollback, workflow, and region failover runbooks.
- `reference/maturity-model.md` - adoption levels and next steps for teams/platforms.
- `reference/evaluation-prompts.md` - prompts to test whether the skill behaves well.
- `reference/production-guide.md` - enterprise defaults, ownership, SLOs, runbooks, and platform choices.
- `reference/message-contract-template.md` - CloudEvents + AsyncAPI contract starter.
- `reference/schema-migration.md` - concrete walkthrough for adding/renaming/removing event-contract fields without breaking consumers.
- `reference/cost-and-finops.md` - cost-aware operation: retention, per-event pricing, cross-region egress, queue depth vs spend.

**Cloud and platform mapping** (load when target cloud or platform is in scope):
- `reference/aws-service-mapping.md` - AWS-neutral mapping for SQS, SNS, EventBridge, Lambda, Kinesis, MSK, DynamoDB Streams, Step Functions, and S3.
- `reference/platform-service-mapping.md` - GCP, Azure, Kafka, RabbitMQ, NATS, Pulsar, and cloud-neutral mapping.

**Code reference** (load only when the user explicitly asks for implementation code):
- `reference/go-examples.md` - production-oriented Go snippets at pattern boundaries (outbox, idempotent receiver, DLQ, retry, Temporal saga). Library choices in these snippets are illustrative, not prescriptive.
- `reference/go-implementation-patterns.md` - Go worker pools, timeouts, idempotency interfaces, shutdown, and workflow reminders.
- `reference/webhook-security-go.md` - webhook signature verification with the boundary pattern in Go.
- `reference/grpc-streaming.md` - gRPC server-streaming, bidirectional streams, deadlines, retry interceptors.
- `reference/llm-workflow-patterns.md` - async LLM inference queueing, bounded retry, model-output validation, streaming token handoff.
- `reference/non-go-pointers.md` - language-pointers for Java, TypeScript, and Python: where the patterns live in each ecosystem, with library options not picks.

## Mandatory Agent Contract

When this skill activates, every answer must include or perform these steps:

1. Name the integration, distributed-systems, and architecture pattern(s) in play.
2. Run the 8-question reliability checklist before writing or accepting code.
3. Flag anti-patterns directly, especially dual-write, missing idempotency, unbounded retries, and missing DLQ ownership.
4. Cite the modern tool or protocol that realizes the pattern.
5. **Default outputs are architectural decisions, contracts, and operational artifacts — not implementation code.** Decisions go in design docs and ADRs. Schemas and event APIs go in `schemas/` and `asyncapi/`. Operational procedures go in runbooks. When the user explicitly asks for code, keep it minimal and at the pattern boundary (outbox insert, idempotent dedup check, retry classifier, ack/commit ordering) rather than full production handlers. Use the language the repo is written in; if no repo language is clear, default to language-agnostic pseudocode rather than picking one.
6. **When code is shown, annotate the pattern at the boundary** with a single comment line such as `// Pattern: Idempotent Receiver - dedupe by event id`. Do not annotate every line; the goal is to make the pattern visible at the point it is enforced.
7. **Recommend tool categories, not specific packages, by default.** Say "a Kafka-compatible broker" or "a CDC tool" before naming Kafka, Redpanda, or Debezium. Specific package recommendations (which Kafka client, which ORM, which HTTP framework) are team decisions; offer them only if the user asks "which library should I use?" In that case, list 2-3 options with the trade-offs that distinguish them, and refuse to pick on the team's behalf.
8. Map readiness to the tier defined in `reference/production-guide.md` (Prototype → Service-ready → Production-ready → Enterprise-critical). Do not call code "production-ready" or "enterprise-critical" while reliability or distributed-systems checklist items are unanswered; downgrade to "service-ready" or "prototype" as appropriate and state the gaps.
9. If AWS services are in scope, load `reference/aws-service-mapping.md` and map the pattern to the AWS service without making the design AWS-only.
10. If the risk is scale, consistency, resilience, service boundaries, multi-region, or enterprise operations, load `reference/distributed-systems-guide.md` and name the distributed-systems pattern(s), not only the messaging pattern(s).
11. If the user asks for an architecture doc, design doc, RFC, ADR, technical plan, migration plan, or decision reference, load `reference/architecture-documentation.md` and produce a decision-ready document with patterns, alternatives, trade-offs, rollout, verification, and operations.
12. For production-readiness, launch, incident, security, or testing requests, load the specific guide: `security-compliance.md`, `testing-strategy.md`, `operational-runbooks.md`, `failure-modes.md`, or `maturity-model.md`.
13. **Write deliverable artifacts to files on disk, not just to chat.** When the response is a design doc, ADR, RFC, implementation plan, message contract, runbook, launch decision, or any structured multi-section document the user is likely to keep, write it under `docs/` (or the repo's existing convention) using a stable path: `docs/designs/<slug>-design.md`, `docs/adr/NNNN-<slug>.md`, `docs/architecture/<slug>-<doctype>.md`, `docs/contracts/<channel>.md`, `schemas/<channel>.<ext>`, `asyncapi/<channel>.yaml`, `docs/runbooks/<slug>.md`, or `docs/launches/<slug>-<YYYY-MM-DD>.md`. After writing, emit a one-line confirmation naming the path - do not paste the full document back into chat. Skip the file write only on an explicit opt-out signal: `show in chat only`, `don't write a file`, `chat only`, or `no file`. The bare verb "show" or phrases like "show me X before Y" are about response *ordering*, not output medium, and must not trigger the escape hatch. Conversational analyses (review findings, readiness assessment, failure-mode discussion) stay in chat by default.

    Every deliverable artifact must include a **`## System concerns`** section near the top (after Summary, before the topic-specific structure) covering the layer beyond code: ownership/Conway boundary, tenancy, cost owner, compliance class, capacity expectation, DR posture, and lifecycle/retirement plan. Leave any field as `<TBD>` if unknown rather than omitting it - the placeholder forces the question to be asked.

14. **Design docs are decision artifacts, not code artifacts.** A design doc captures patterns chosen, boundary contracts at the conceptual level (channel names, ordering keys, idempotency keys, retention, DLQ owner, compatibility mode), file/component inventory, alternatives, open questions, and readiness tier. Implementation code belongs in source files, not in the design doc. Schema files belong in `schemas/` and `asyncapi/` produced by `/contract`. Runbooks belong in `docs/runbooks/`. If the user wants code after the design lands, treat that as a follow-up step.

15. **Cross-link artifacts and include summary metadata.** Every file the skill writes (design, ADR, RFC, contract, runbook, launch decision) must include:

    a. A `## Summary` block at the top with: `Status:` (Draft | Proposed | Accepted | Superseded | Retired), `Date:` (`<YYYY-MM-DD>`), and a 1-2 sentence TL;DR.

    b. A `## Related artifacts` section at the bottom that lists peer docs for the same feature/slug. Before writing, glob the repo for these patterns and include the matches (use Glob tool):
       - `docs/designs/<slug>*.md`
       - `docs/architecture/<slug>*.md`
       - `docs/adr/*<slug>*.md`
       - `docs/contracts/<channel>*.md` (where `<channel>` is derived from the feature, e.g. `orders.placed.v1`)
       - `schemas/<channel>*.{json,avsc,proto}`
       - `asyncapi/<channel>*.yaml`
       - `docs/runbooks/*<slug>*.md`
       - `docs/launches/<slug>*.md`

       If matches exist, link them by relative path. If none exist yet, list the conventional paths where they would land if/when produced (so the reader knows what to look for).

    c. Slug consistency: derive a single feature slug from the user's prompt (e.g. `order-fulfillment`, `payment-authorization`, `webhook-ingestion`) and use it consistently across all files for that feature. Channel names (`orders.placed.v1`) are separate from feature slugs and may not match exactly; the contract uses the channel name in its filename.

    d. Reading-before-writing: when writing an artifact for a feature where related docs already exist, the agent should read those docs (at least their Summary blocks) so the new artifact's decisions are consistent with prior ones - particularly patterns named, ordering keys, owner team, and channel names.

16. **Maintain a per-service index doc.** Every artifact-writing command, after writing its main file, must also create or update `docs/services/<slug>/README.md` for the feature's service. This per-service README aggregates every artifact for that service into one entry point. Use this template, filling sections that apply and leaving placeholders where information is unknown:

    ```markdown
    # <Service Name>

    ## Service info
    - **Owner team**: <team / Slack / on-call>
    - **SLO**: <user-journey or service-level SLO>
    - **Tier**: Prototype | Service-ready | Production-ready | Enterprise-critical
    - **Last reviewed**: <YYYY-MM-DD>

    ## System concerns (the layer beyond code)
    - **Tenancy**: <single-tenant | multi-tenant with what isolation>
    - **Compliance**: <none | PII | GDPR | SOC2 | PCI | data residency>
    - **Cost owner**: <team or cost center>
    - **Capacity**: <expected volume p50/p99, growth assumption>
    - **DR posture**: <RPO / RTO / region strategy>
    - **Lifecycle**: <created date; deprecation trigger; replacement plan>

    ## Artifacts
    - **Design**: <docs/designs/<slug>-design.md or "(not yet written)">
    - **ADRs**: <list of docs/adr/*<slug>*.md or "(none)">
    - **Contracts**: <list of docs/contracts/*.md owned by this service>
    - **Runbooks**: <list of docs/runbooks/*<slug>*.md>
    - **Launch decisions**: <list of docs/launches/<slug>-*.md>

    Do NOT pre-list "Planned" artifacts beyond what already exists; the index reflects state, not roadmap. The user can ask explicitly for a roadmap if they want one.

    ## Dependencies
    - **Upstream services**: <list>
    - **Downstream services**: <list>
    - **External services**: <list>
    - **Shared infrastructure**: <list>

    ## Channels owned
    - <channel-name>: <produced | consumed | both>. See <link to contract>.
    ```

    Keep the per-service README tight. Aim for 30-60 lines total. Each system-concerns line is one phrase, not a paragraph. Each dependency entry is one bullet, not three sub-bullets.

    On every artifact write, append or update the relevant section: `/design` populates Service info + Artifacts.Design + System concerns; `/contract` adds an entry to Channels owned and links the contract; `/runbook` adds to Artifacts.Runbooks; `/architecture` adds to Artifacts.ADRs; `/ship` adds to Artifacts.Launch decisions and updates Tier + Last reviewed. If the file does not exist, create it with placeholders.

17. **Maintain a system-level catalog.** Whenever a per-service README is created or updated, the command must also create or update `docs/system/catalog.md` with one row per service. Use this template:

    ```markdown
    # System Catalog

    Last updated: <YYYY-MM-DD>

    | Service | Owner | Tier | SLO | Compliance | Last reviewed | Index |
    | --- | --- | --- | --- | --- | --- | --- |
    | <slug> | <team> | <tier> | <SLO> | <PII/GDPR/none> | <YYYY-MM-DD> | [README](../services/<slug>/README.md) |

    ## Cross-cutting concerns

    - **Org topology**: links to docs/system/org-topology.md if it exists.
    - **Capacity envelope**: link to docs/system/capacity.md if it exists.
    - **Compliance map**: link to docs/system/compliance.md if it exists.
    - **DR posture**: link to docs/system/dr.md if it exists.
    ```

    Sort the table alphabetically by slug. Do not invent entries for services that have no per-service README. The catalog is a registry of what exists, not aspirational.

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
