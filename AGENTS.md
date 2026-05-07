# Agent Instructions - Distributed Systems Patterns Skill

This is the cross-tool entry point for Codex, Claude, OpenCode, Aider, Cursor, and other agents that auto-load `AGENTS.md`. The canonical skill is [`SKILL.md`](./SKILL.md); this file keeps the activation policy and non-negotiable rules inline so an agent can act without loading every reference file.

## Activation

Apply this skill whenever the task involves designing systems at scale: integration, messaging, event-driven decisions and contracts, webhooks, queues, topics, brokers, async workflows, service-to-service consistency, message contracts, microservices, distributed systems, scaling, resilience, multi-region, or enterprise service architecture - plus the layer beyond code (team ownership and Conway boundaries, multi-tenancy, cost ownership, compliance, capacity, DR, lifecycle, governance). Six commands (`/design`, `/contract`, `/architecture`, `/review`, `/runbook`, `/prelaunch`) produce durable artifacts; the skill does not generate implementation code or tests.

## Connected system

This skill is six commands that share one artifact layout. Every artifact lives under one per-feature folder, and every write updates two index docs so the design stays navigable:

- `docs/features/<slug>/README.md` aggregates a feature's info, system concerns, artifacts, dependencies, and owned channels. Sibling folders under it hold the artifacts: `design.md`, `adrs/`, `contracts/`, `schemas/`, `asyncapi/`, `runbooks/`, `launches/`.
- `docs/system/catalog.md` lists every feature with one row each, linking to the per-feature README. Platform-wide ADRs that span features live at `docs/system/adrs/NNNN-<title>.md`.

**Shared knowledge** lives at `docs/system/`. Platform-wide ADRs land in `docs/system/adrs/` (use `/architecture` at platform scope), platform-wide runbooks in `docs/system/runbooks/` (use `/runbook` at platform scope), and platform standards as plain markdown under `docs/system/standards/<topic>.md`. Optional top-level docs (`glossary.md`, `topology.md`, `capacity.md`, `compliance.md`, `dr.md`) hold cross-cutting reference data. Feature artifacts reference these by relative path (`../../system/...`) rather than restating their content. Before writing a feature artifact, Glob `docs/system/` for applicable shared docs.

Reader navigation: `docs/system/catalog.md` -> `docs/features/<slug>/README.md` -> any artifact under `docs/features/<slug>/{design,adrs,contracts,schemas,asyncapi,runbooks,launches}`. See SKILL.md items 16-17 for templates.

Trigger signals:

- Tech: Kafka, RabbitMQ, SQS, SNS, EventBridge, Pub/Sub, Service Bus, Event Grid, NATS, MQTT, Redis Streams, ActiveMQ, Solace, Pulsar, Redpanda, Sidekiq, BullMQ, Celery, Temporal, Step Functions, Camunda, Debezium, Kafka Connect, Schema Registry, AsyncAPI, CloudEvents, OpenTelemetry, Kubernetes, KEDA, Envoy, Istio, Linkerd, Dapr, Redis, CDN, API gateway, Consul, etcd, ZooKeeper.
- Concepts: queue, topic, channel, broker, event, command, message, async, pub/sub, fan-out, saga, process manager, outbox, inbox, CDC, idempotency, DLQ, retry, dead-letter, replay, event sourcing, CQRS, choreography, orchestration, durable execution, partition, offset, consumer group, schema evolution, service boundary, bounded context, cache, shard, replica, rate limit, circuit breaker, bulkhead, backpressure, load shedding, autoscaling, multi-region, tenant isolation, SLO.
- Code shape: producing/consuming messages, webhook delivery, cross-service writes, Lambda event sources, `@KafkaListener`, `pubsub.Subscribe`, `@MessagePattern`, `events/*.proto`, `*.avsc`, AsyncAPI specs, retry/DLQ/partition config, Kubernetes HPA/KEDA manifests, Helm/Terraform service config, service mesh traffic policy, rate limiter, cache/shard code.
- Review: PRs that publish, consume, route, transform, retry, dead-letter, replay, or version messages.

Do not apply for pure local request-response, pure frontend work, single-process queues with no service boundary, or ETL with no service coordination.

## Mandatory Process

1. **Name the pattern(s).** Use the table below; load [`reference/catalog.md`](./reference/catalog.md) for full pattern details.
2. **Run the 8-question reliability checklist.** Map readiness to the tier defined in `reference/production-guide.md` (Prototype, Service-ready, Production-ready, Enterprise-critical). Downgrade rather than refuse when checklist items are open, and state the gaps.
3. **Flag anti-patterns explicitly.** Especially dual-write, missing idempotency, ack-before-commit, unbounded retries, and DLQ-with-no-owner.
4. **Cite the modern realization.** Examples: Kafka consumer group, SQS DLQ/redrive, Debezium outbox SMT, CloudEvents, AsyncAPI, Schema Registry, OpenTelemetry, Temporal.
5. **Default outputs are architectural decisions, contracts, and operational artifacts — not implementation code.** Decisions go in design docs and ADRs. Schemas and event APIs go in `docs/features/<slug>/schemas/` and `docs/features/<slug>/asyncapi/`. Operational procedures go in runbooks. When the user explicitly asks for code, keep it minimal and at the pattern boundary (outbox insert, idempotent dedup check, retry classifier, ack/commit ordering) rather than full production handlers. Use the language the repo is written in; if no repo language is clear, default to language-agnostic pseudocode rather than picking one.
6. **When code is shown, annotate the pattern at the boundary** with a single comment line such as `// Pattern: Idempotent Receiver - dedupe by event id`. Do not annotate every line; the goal is to make the pattern visible at the point it is enforced.
7. **For AWS implementations, pattern first and service second.** Load [`reference/aws-service-mapping.md`](./reference/aws-service-mapping.md) and map system design concepts to SQS, SNS, EventBridge, Lambda event source mappings, Kinesis, MSK, DynamoDB Streams, Step Functions, and S3 without making non-AWS designs AWS-specific.
8. **For distributed-system risks, name those patterns too.** Load [`reference/distributed-systems-guide.md`](./reference/distributed-systems-guide.md) for boundaries, consistency, scaling, resilience, caching, sharding, multi-region, service mesh, SLOs, and governance.
9. **For architecture documents, produce decision-ready artifacts.** Load [`reference/architecture-documentation.md`](./reference/architecture-documentation.md) for design docs, RFCs, ADRs, implementation plans, migration plans, diagrams, trade-offs, rollout, and verification.
10. **For production usage, use practical guides.** Load scenario playbooks, failure modes, security/compliance, testing strategy, operational runbooks, maturity model, or platform mappings when they match the request.
11. **Reference shared knowledge before restating.** Glob `docs/system/standards/`, `docs/system/glossary.md`, `docs/system/compliance.md`, `docs/system/dr.md`, `docs/system/topology.md` before writing feature artifacts; link them rather than copy-pasting their content.
12. **Keep the system navigable.** After writing any artifact, update `docs/features/<slug>/README.md` and `docs/system/catalog.md` so the system stays navigable. See SKILL.md items 15-16.

## Pattern Selection Excerpt

| Need                          | Pattern                                       | Modern realization                                     |
| ----------------------------- | --------------------------------------------- | ------------------------------------------------------ |
| send work to one of N workers | Point-to-Point Channel + Competing Consumers  | Kafka consumer group; SQS; RabbitMQ queue              |
| broadcast to many consumers   | Publish-Subscribe Channel                     | Kafka topic + groups; SNS; Pub/Sub; EventBridge        |
| atomic DB write + publish     | Transactional Client via Outbox + CDC         | Outbox table + Debezium -> Kafka                       |
| absorb duplicates             | Idempotent Receiver                           | DB unique key; Redis `SETNX`; DynamoDB conditional put |
| handle bad messages           | Invalid Message Channel + Dead Letter Channel | Kafka DLT; SQS DLQ/redrive; RabbitMQ DLX               |
| long-running multi-step flow  | Process Manager (Saga)                        | Temporal; Step Functions; Camunda 8                    |

Full table: [`SKILL.md`](./SKILL.md) Process section and [`reference/decision-tree.md`](./reference/decision-tree.md).

## 8-Question Reliability Checklist

Always answer before writing or approving integration code:

1. **Delivery guarantee?** at-most-once / at-least-once / effectively-once.
2. **Idempotency strategy?** key + store.
3. **Bad-message strategy?** invalid-message path + DLQ with owner.
4. **Retry policy?** bounded, backoff, jitter, classification.
5. **Ordering?** total / per-key / none.
6. **Schema evolution?** registry + CI compatibility gate.
7. **Observability?** `traceparent` + lag/age/DLQ-depth metrics.
8. **Failure boundary?** rollback, compensation, replay.

If any answer is "later", stop and answer it now.

Full guidance: [`SKILL.md`](./SKILL.md) and [`reference/checklist.md`](./reference/checklist.md).

## Distributed Systems Checklist

Use when the task is about service boundaries, scale, resilience, multi-region, or enterprise operations:

1. **Boundary and ownership?** Which service/team owns the data, API, SLO, and on-call path?
2. **Consistency model?** Strong, read-your-writes, causal, eventual, or best-effort?
3. **Scaling axis?** Replicas, partitions/shards, tenants, regions, async buffering, cache/CDN, or read replicas?
4. **Failure mode?** Timeouts, retry storms, slow dependencies, partial outages, deploy rollback, and region loss.
5. **Backpressure?** Where are queues bounded, requests rejected, rate limits enforced, and overload signaled?
6. **Operations?** SLOs, dashboards, alerts, runbooks, capacity plan, security boundary, tenant isolation, and cost controls.

## Code Rules

When generating integration code:

- Code is shown only when the user asks for it. When asked, use the repo language or language-agnostic pseudocode; do not impose Go on a non-Go repo. Recommend tool categories before specific packages.
- Use CloudEvents envelope fields and semantic channel names.
- Propagate OpenTelemetry trace context on every hop.
- Make retries, DLQs, idempotency, ack/commit, and shutdown visible.
- Use Outbox for DB write + publish; use Inbox/dedup for consuming side effects.
- Keep routers/translators declarative; keep business logic in consumers/workflows.
- On AWS, check visibility timeout, partial batch response, EventBridge archive/replay, DLQ owner/redrive, Step Functions compensation, IAM least privilege, and DynamoDB conditional idempotency.
- Load [`reference/go-examples.md`](./reference/go-examples.md) only when the user explicitly requests Go boundary snippets.

## Top Anti-Patterns

- `db.save(); broker.publish();` - dual-write; needs Outbox + CDC or a transactional producer when fully inside Kafka.
- At-least-once delivery + non-idempotent receiver.
- Auto-commit/ack before processing commits state.
- Unbounded retries or no DLQ.
- Distributed monolith: services cannot deploy independently.

Full list: [`SKILL.md`](./SKILL.md) Anti-Patterns section.

## References

- Full pattern catalog: [`reference/catalog.md`](./reference/catalog.md)
- Decision tree: [`reference/decision-tree.md`](./reference/decision-tree.md)
- Review checklist: [`reference/checklist.md`](./reference/checklist.md)
- Agent workflow: [`reference/agent-workflow.md`](./reference/agent-workflow.md)
- Distributed systems guide: [`reference/distributed-systems-guide.md`](./reference/distributed-systems-guide.md)
- Architecture documentation: [`reference/architecture-documentation.md`](./reference/architecture-documentation.md)
- Architecture examples: [`reference/architecture-examples.md`](./reference/architecture-examples.md)
- Modern field guide: [`reference/modern-integration-field-guide.md`](./reference/modern-integration-field-guide.md)
- AWS service mapping: [`reference/aws-service-mapping.md`](./reference/aws-service-mapping.md)
- Platform service mapping: [`reference/platform-service-mapping.md`](./reference/platform-service-mapping.md)
- Scenario playbooks: [`reference/scenario-playbooks.md`](./reference/scenario-playbooks.md)
- Failure modes: [`reference/failure-modes.md`](./reference/failure-modes.md)
- Testing strategy: [`reference/testing-strategy.md`](./reference/testing-strategy.md)
- Security and compliance: [`reference/security-compliance.md`](./reference/security-compliance.md)
- Operational runbooks: [`reference/operational-runbooks.md`](./reference/operational-runbooks.md)
- Maturity model: [`reference/maturity-model.md`](./reference/maturity-model.md)
- Evaluation prompts: [`reference/evaluation-prompts.md`](./reference/evaluation-prompts.md)
- Go examples: [`reference/go-examples.md`](./reference/go-examples.md)
- Production guide: [`reference/production-guide.md`](./reference/production-guide.md)
- Message contract template: [`reference/message-contract-template.md`](./reference/message-contract-template.md)
- Schema migration: [`reference/schema-migration.md`](./reference/schema-migration.md)
- Cost and FinOps: [`reference/cost-and-finops.md`](./reference/cost-and-finops.md)
- Non-Go pointers: [`reference/non-go-pointers.md`](./reference/non-go-pointers.md)

Canonical skill: [`SKILL.md`](./SKILL.md).
