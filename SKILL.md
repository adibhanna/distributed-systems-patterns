---
name: distributed-systems-patterns
description: Apply distributed-systems, messaging, and integration patterns to architectural decisions, message contracts, runbooks, and launch decisions for event-driven, microservice, queue, broker, saga, outbox, CDC, workflow, scaling, resilience, and multi-region work. Triggers include Kafka, RabbitMQ, SQS/SNS/EventBridge, Pub/Sub, NATS, Pulsar, Temporal, Step Functions, Debezium, CloudEvents, AsyncAPI, OpenTelemetry, plus idempotency, DLQs, retries, ordering, schema evolution, replay, sharding, backpressure, circuit breaking, autoscaling, SLOs, RFCs, and ADRs. Six commands produce durable artifacts; the skill does not generate implementation code or tests.
version: 0.6.0
tags: [distributed-systems, messaging, event-driven, integration, architecture, microservices, kafka, aws, cloudevents, asyncapi]
---

# Distributed Systems Patterns

## Purpose

This skill produces durable architectural artifacts for distributed systems work: design docs, message contracts, ADRs, runbooks, and launch decisions. Six slash commands write these artifacts; one (`/review`) reads them plus the implementation diff and produces architectural findings.

The artifacts the skill produces (decisions, contracts, runbooks, launch decisions) are valuable when multiple teams or services must coordinate. The skill does NOT generate implementation code or tests - that's your team's job in their normal dev environment. The skill's value is in the decision and review layer, where teams typically under-invest.

The skill is technology-neutral. Specific package picks (which Kafka client, which ORM) are team decisions; the skill recommends categories. Default outputs are architectural artifacts at canonical paths under `docs/features/<slug>/` and `docs/system/`.

## Who this skill is for

Distributed-systems engineers, tech leads, staff/principal engineers, platform teams, and architects making cross-service decisions at scale. Six commands produce durable artifacts (design docs, ADRs, contracts, runbooks, launch decisions) that are valuable when multiple teams or services must coordinate; they are overhead when one engineer can hold the whole system in their head.

**Not for**: single-process apps, single-function utilities, frontend-only work, quick local refactors, ETL jobs without service coordination, beginner pattern questions ("what is a queue?"), or pre-MVP prototypes that don't yet have users or operational costs.

**Threshold for invoking the skill**: at least two services or two teams must coordinate; or the work introduces durable infrastructure (broker, workflow engine, schema registry, mesh, cache fleet, shard, new consistency model); or the request explicitly asks for an ADR / RFC / runbook / launch decision.

**Decline behavior when below the threshold**: if the user invokes the skill (via vocabulary trigger or slash command) on a problem that does not meet the threshold, the skill must explicitly decline. Tell the user one sentence about why ("This is a single-process refactor; a regular prompt is faster") and answer the question simply, without producing design docs / ADRs / contracts. Examples that should trigger decline:

- A single-team prototype, hackathon, or side project.
- A single-process app with one database and no async work.
- A frontend-only change.
- A "what is X?" beginner pattern question (answer the question; don't run the pipeline).
- An ETL job that doesn't cross service or team boundaries.

When in doubt about whether the threshold is met, ask the user one question: "How many services/teams will this touch, and is this for production with real users?" before deciding whether to run the pipeline.

## Shared knowledge across features

Some knowledge applies to every feature, not just one. The skill organizes this under `docs/system/`:

- `docs/system/catalog.md` - the service/feature registry
- `docs/system/adrs/` - **platform-wide** decisions (broker choice, mesh policy, schema-registry vendor, multi-region strategy)
- `docs/system/runbooks/` - **platform-wide** runbooks (broker outage, schema-registry rollback, region-wide failover)
- `docs/system/standards/` - conventions every feature must follow (channel naming, observability, security baseline, deployment, on-call expectations)
- `docs/system/glossary.md` - shared vocabulary (domain terms used by multiple features)
- `docs/system/topology.md` - team ownership map and Conway-Law boundaries
- `docs/system/capacity.md` - platform capacity envelope (broker throughput, total cost budget, regional limits)
- `docs/system/compliance.md` - PII / GDPR / SOC2 / data-residency baseline that all features inherit
- `docs/system/dr.md` - DR strategy and region-failover plan that applies across features

**The principle: reference, don't restate.** When a feature design touches a shared concern (e.g. "follows the platform observability standard"), link to the shared doc rather than copy-pasting the rule into every feature. If the same fact appears in three feature docs, it belongs in `docs/system/standards/` instead.

Feature artifacts cross-link into `docs/system/` using `../../system/<path>` (one `..` for the feature subdir, one for `features/`). The per-feature README's `## Shared references` section names which platform docs apply to this feature.

This skill is an operating procedure. Load only the reference file needed:

**Operating context loaded automatically when relevant** (these live in the user's repo, not the skill):
- `docs/system/standards/*.md` - platform conventions (when a feature artifact would touch a convention)
- `docs/system/adrs/*.md` - platform-wide decisions (when a feature artifact must comply)
- `docs/system/glossary.md` - shared vocabulary (when domain terms might be ambiguous)
- `docs/system/topology.md` - team ownership map (when ownerlaunch decisions matter)

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

**Code patterns (loaded only when the user explicitly asks for boundary code snippets)**:
- `reference/go-examples.md` - production-oriented Go snippets at pattern boundaries (outbox, idempotent receiver, DLQ, retry, Temporal saga). Library choices in these snippets are illustrative, not prescriptive.
- `reference/non-go-pointers.md` - language-pointers for Java, TypeScript, and Python: where the patterns live in each ecosystem, with library options not picks.

## Mandatory Agent Contract

When this skill activates, every answer must include or perform these steps:

1. Name the integration, distributed-systems, and architecture pattern(s) in play.
2. Run the 8-question reliability checklist before writing or accepting code.
3. Flag anti-patterns directly, especially dual-write, missing idempotency, unbounded retries, and missing DLQ ownership.
4. Cite the modern tool or protocol that realizes the pattern.
5. **Default outputs are architectural decisions, contracts, and operational artifacts — not implementation code.** Decisions go in design docs and ADRs. Schemas and event APIs go in `docs/features/<slug>/schemas/` and `docs/features/<slug>/asyncapi/`. Operational procedures go in runbooks. When the user explicitly asks for code, keep it minimal and at the pattern boundary (outbox insert, idempotent dedup check, retry classifier, ack/commit ordering) rather than full production handlers. Use the language the repo is written in; if no repo language is clear, default to language-agnostic pseudocode rather than picking one.
6. **When code is shown, annotate the pattern at the boundary** with a single comment line such as `// Pattern: Idempotent Receiver - dedupe by event id`. Do not annotate every line; the goal is to make the pattern visible at the point it is enforced.
7. **Recommend tool categories, not specific packages, by default.** Say "a Kafka-compatible broker" or "a CDC tool" before naming Kafka, Redpanda, or Debezium. Specific package recommendations (which Kafka client, which ORM, which HTTP framework) are team decisions; offer them only if the user asks "which library should I use?" In that case, list 2-3 options with the trade-offs that distinguish them, and refuse to pick on the team's behalf.
8. Map readiness to the tier defined in `reference/production-guide.md` (Prototype → Service-ready → Production-ready → Enterprise-critical). Do not call code "production-ready" or "enterprise-critical" while reliability or distributed-systems checklist items are unanswered; downgrade to "service-ready" or "prototype" as appropriate and state the gaps.
9. If AWS services are in scope, load `reference/aws-service-mapping.md` and map the pattern to the AWS service without making the design AWS-only.
10. If the risk is scale, consistency, resilience, service boundaries, multi-region, or enterprise operations, load `reference/distributed-systems-guide.md` and name the distributed-systems pattern(s), not only the messaging pattern(s).
11. If the user asks for an architecture doc, design doc, RFC, ADR, technical plan, migration plan, or decision reference, load `reference/architecture-documentation.md` and produce a decision-ready document with patterns, alternatives, trade-offs, rollout, verification, and operations.
12. **Write deliverable artifacts to files on disk, not just to chat.** When the response is a design doc, ADR, RFC, implementation plan, message contract, runbook, launch decision, or any structured multi-section document the user is likely to keep, write it under `docs/` (or the repo's existing convention) using one of the canonical paths under the per-feature folder layout:
    - Design doc -> `docs/features/<slug>/design.md`
    - ADR (feature-scoped, default) -> `docs/features/<slug>/adrs/NNNN-<title>.md`
    - ADR (platform-wide) -> `docs/system/adrs/NNNN-<title>.md`
    - RFC / Architecture Overview / Implementation Plan / Migration Plan / Production Readiness Review -> `docs/features/<slug>/architecture-<doctype>.md` (or `docs/system/architecture-<doctype>.md` for platform-wide)
    - Contract -> `docs/features/<slug>/contracts/<channel>.md` plus `docs/features/<slug>/schemas/<channel>.<ext>` plus `docs/features/<slug>/asyncapi/<channel>.yaml`
    - Runbook -> `docs/features/<slug>/runbooks/<incident>.md`
    - Launch decision -> `docs/features/<slug>/launches/<YYYY-MM-DD>.md`

    The slug derives from the feature/service the artifact belongs to. ADR numbering is per-folder; a feature-scoped ADR-0001 in one feature does not collide with a feature-scoped ADR-0001 in another. Platform-wide ADRs use a separate number sequence under `docs/system/adrs/`.

    After writing, emit a one-line confirmation naming the path - do not paste the full document back into chat. Skip the file write only on an explicit opt-out signal: `show in chat only`, `don't write a file`, `chat only`, or `no file`. The bare verb "show" or phrases like "show me X before Y" are about response *ordering*, not output medium, and must not trigger the escape hatch. Conversational analyses (review findings, readiness assessment, failure-mode discussion) stay in chat by default.

    Every deliverable artifact must include a **`## System concerns`** section near the top (after Summary, before the topic-specific structure) covering the layer beyond code: ownership/Conway boundary, tenancy, cost owner, compliance class, capacity expectation, DR posture, and lifecycle/retirement plan. Leave any field as `<TBD>` if unknown rather than omitting it - the placeholder forces the question to be asked.

13. **Design docs are decision artifacts, not code artifacts.** A design doc captures patterns chosen, boundary contracts at the conceptual level (channel names, ordering keys, idempotency keys, retention, DLQ owner, compatibility mode), file/component inventory, alternatives, open questions, and readiness tier. Implementation code belongs in source files, not in the design doc. Schema files belong in `docs/features/<slug>/schemas/` and `docs/features/<slug>/asyncapi/` produced by `/contract`. Runbooks belong in `docs/features/<slug>/runbooks/`. If the user wants code after the design lands, treat that as a follow-up step.

14. **Cross-link artifacts and include summary metadata.** Every file the skill writes (design, ADR, RFC, contract, runbook, launch decision) must include:

    a. A `## Summary` block at the top with: `Status:` (Draft | Proposed | Accepted | Superseded | Retired), `Date:` (`<YYYY-MM-DD>`), and a 1-2 sentence TL;DR.

    b. A `## Related artifacts` section at the bottom that lists peer docs for the same feature/slug. Before writing, glob the repo for these patterns and include the matches (use Glob tool):
       - `docs/features/<slug>/design.md`
       - `docs/features/<slug>/adrs/*.md`
       - `docs/features/<slug>/contracts/*.md`
       - `docs/features/<slug>/schemas/*`
       - `docs/features/<slug>/asyncapi/*.yaml`
       - `docs/features/<slug>/runbooks/*.md`
       - `docs/features/<slug>/launches/*.md`
       - `docs/system/adrs/*.md` (platform-wide ADRs that may apply)

       If matches exist, link them by relative path. If none exist yet, list the conventional paths where they would land if/when produced (so the reader knows what to look for).

    c. Slug consistency: derive a single feature slug from the user's prompt (e.g. `order-fulfillment`, `payment-authorization`, `webhook-ingestion`) and use it consistently across all files for that feature. Channel names (`orders.placed.v1`) are separate from feature slugs and may not match exactly; the contract uses the channel name in its filename.

    d. Reading-before-writing: when writing an artifact for a feature where related docs already exist, the agent should read those docs (at least their Summary blocks) so the new artifact's decisions are consistent with prior ones - particularly patterns named, ordering keys, owner team, and channel names.

15. **Maintain a per-feature index doc.** Every artifact-writing command, after writing its main file, must also create or update `docs/features/<slug>/README.md` for the feature. This per-feature README aggregates every artifact for that feature into one entry point. Use this template, filling sections that apply and leaving placeholders where information is unknown:

    ```markdown
    # <Feature Name>

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

    ## Shared references

    Platform docs that apply to this feature. Link rather than restate.

    - **Standards followed**: <list relevant docs/system/standards/*.md by relative path, e.g. `../../system/standards/channel-naming.md`>
    - **Glossary**: <link to docs/system/glossary.md if relevant terms apply>
    - **Compliance baseline**: <link to docs/system/compliance.md if applicable>
    - **DR plan**: <link to docs/system/dr.md if this feature is in DR scope>
    - **Platform ADRs that govern this feature**: <list applicable docs/system/adrs/*.md>

    ## Artifacts
    - **Design**: <link to design.md or "(not yet written)">
    - **ADRs**: <list of links to adrs/NNNN-<title>.md or "(none)">
    - **Contracts**: <list of links to contracts/<channel>.md or "(none)">
    - **Runbooks**: <list of links to runbooks/<incident>.md or "(none)">
    - **Launch decisions**: <list of links to launches/<date>.md or "(none)">

    Do NOT pre-list "Planned" artifacts beyond what already exists; the index reflects state, not roadmap. The user can ask explicitly for a roadmap if they want one.

    ## Dependencies
    - **Upstream services**: <list>
    - **Downstream services**: <list>
    - **External services**: <list>
    - **Shared infrastructure**: <list>

    ## Channels owned
    - <channel-name>: <produced | consumed | both>. See <link to contract>.
    ```

    > If a feature genuinely needs a value that diverges from a shared standard, document the divergence in the feature's README under `## System concerns` rather than silently overriding. If many features diverge the same way, the standard itself is wrong - update it instead.

    Links inside the per-feature README are relative to the README itself: `design.md`, `adrs/NNNN-<title>.md`, `contracts/<channel>.md`, `runbooks/<incident>.md`, `launches/<date>.md` work directly without `../` traversal.

    Keep the per-feature README tight. Aim for 30-60 lines total. Each system-concerns line is one phrase, not a paragraph. Each dependency entry is one bullet, not three sub-bullets.

    On every artifact write, append or update the relevant section. Paths are relative to the README at `docs/features/<slug>/README.md`:
    - `/design` populates `## Service info`, sets `## Artifacts.Design = design.md`, and fills `## System concerns`.
    - `/architecture` for a feature-scoped ADR appends `adrs/NNNN-<title>.md` to `## Artifacts.ADRs`.
    - `/contract` appends `contracts/<channel>.md` to `## Artifacts.Contracts` and adds an entry to `## Channels owned` linking to `contracts/<channel>.md`.
    - `/runbook` appends `runbooks/<incident>.md` to `## Artifacts.Runbooks`.
    - `/prelaunch` appends `launches/<date>.md` to `## Artifacts.Launch decisions`, and updates `## Service info.Tier` and `## Service info.Last reviewed`.

    If the file does not exist, create it with placeholders.

16. **Maintain a system-level catalog.** Whenever a per-feature README is created or updated, the command must also create or update `docs/system/catalog.md` with one row per feature. Use this template:

    ```markdown
    # System Catalog

    Last updated: <YYYY-MM-DD>

    | Feature | Owner | Tier | SLO | Compliance | Last reviewed | Index |
    | --- | --- | --- | --- | --- | --- | --- |
    | <slug> | <team> | <tier> | <SLO> | <PII/GDPR/none> | <YYYY-MM-DD> | [README](../features/<slug>/README.md) |

    ## Cross-cutting concerns

    | Concern | Doc | Status |
    | --- | --- | --- |
    | Org topology | [topology.md](topology.md) | <Draft / Active / TBD> |
    | Capacity envelope | [capacity.md](capacity.md) | <status> |
    | Compliance baseline | [compliance.md](compliance.md) | <status> |
    | DR strategy | [dr.md](dr.md) | <status> |
    | Glossary | [glossary.md](glossary.md) | <status> |
    | Standards | [standards/](standards/) | <count> standards documented |
    | Platform-wide ADRs | [adrs/](adrs/) | <count> decisions, latest <NNNN> |
    | Platform runbooks | [runbooks/](runbooks/) | <count> runbooks |

    Rows should be removed if the corresponding doc/folder does not exist (a row with link `topology.md` requires the file to exist; otherwise omit the row entirely).
    ```

    Sort the table alphabetically by slug. Do not invent entries for features that have no per-feature README. The catalog is a registry of what exists, not aspirational. Platform standards (plain markdown under `docs/system/standards/`), platform-wide ADRs from `/architecture --scope=platform`, and platform runbooks from `/runbook --scope=platform` populate the cross-cutting concerns table as files appear; the catalog reflects state, not aspiration.

    The catalog uses the term **feature** (matching the folder name `docs/features/<slug>/`) rather than "service" because a feature may span multiple services or sub-systems. The slug is the same identifier used across all artifacts for that feature.

17. **Reference shared knowledge before restating it.** Before writing any feature artifact (design, contract, runbook, ADR, launch decision), Glob `docs/system/standards/*.md`, `docs/system/glossary.md`, `docs/system/compliance.md`, `docs/system/dr.md`, `docs/system/topology.md`, and `docs/system/adrs/*.md`. If a shared doc covers a concern the feature artifact would otherwise restate (e.g. observability conventions, channel-naming rules, compliance class, DR posture), reference the shared doc by path instead of copy-pasting its content. The feature's `## Shared references` section in its per-feature README captures which shared docs apply.

    Platform standards live as plain markdown under `docs/system/standards/<topic>.md`; users author them directly or use `/architecture` at platform scope. If a shared doc does not yet exist for a recurring concern (the same convention restated in 3+ features), surface that in chat as a recommendation: "Consider promoting <concept> to docs/system/standards/<topic>.md so all features can reference it." Do not auto-create platform docs without explicit user direction.

18. **Auto self-check before declaring artifact-writing work complete.** After every artifact-writing command (`/design`, `/contract`, `/architecture`, `/runbook`, `/prelaunch`), run a quick self-check pass before returning. The self-check is a subset of `/review` focused on inconsistencies and traps the agent should catch in its own work:

    - **Anti-pattern scan** against the just-produced artifact (dual-write, ack-before-commit, unbounded retry, missing DLQ owner, distributed monolith, shared OLTP, distributed 2PC).
    - **Cross-file consistency**: contract ordering keys match the design's declared keys; channel names in contracts match channel names in the design's Boundary contracts section; system concerns in the contract match the design's System concerns.
    - **Schema evolution traps**: if the schema has `additionalProperties: false` or closed enums AND the contract declares BACKWARD compatibility, flag the inconsistency. BACKWARD requires additive changes to be safe; closed schemas break that. Either drop `additionalProperties: false` / open the enum or document the strict consumer-first rollout.
    - **Cross-channel consistency**: when multiple contracts are written in one turn, check that `expirytime`, retention, and ordering policies are consistent across channels (or that variations are justified).
    - **System concerns completeness**: refuse to return an artifact where every system-concerns line is `<TBD>`. Force at least owner, tenancy, and compliance to be specified or explicitly flagged as needing user input.
    - **Cross-link integrity**: verify every relative path in the artifact's `## Related artifacts` section points to a real or conventional path.

    **Critical findings**: fix inline before returning the artifact. Don't ship a known-broken contract.

    **Important findings**: report in chat as a follow-up note ("Self-check flagged: <issue>. The artifact is written; recommend revising via `revise: <change>`."). The artifact is still written so the user has something to react to.

    **Time budget**: target 15-30 seconds for the self-check. If it would take longer, surface only the top 2-3 issues and let the user run a full `/review` for the deeper pass. The self-check is a guardrail, not a replacement for `/review`'s failure-mode walk and readiness verdict.

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
