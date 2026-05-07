# Distributed Systems Patterns Skill

<p align="left">
  <img src="./logo.jpg" alt="Distributed Systems Patterns logo" width="600">
</p>

Six slash commands that produce design docs, message contracts, ADRs, runbooks, and launch decisions for distributed-systems work. Artifacts land on disk under `docs/features/<slug>/`. The skill **does not write code** — your team's dev environment does that.

> Heavy-duty toolkit for production systems with cross-team coordination. **Skip if you're working on a side project, prototype, or single-process app.**

## Who this is for

Use it when **multiple services or teams must coordinate**, when work introduces durable infrastructure (broker, workflow engine, schema registry, mesh), or when decisions need to outlast the code.

**Wrong fit**: solo projects, prototypes, hackathons, frontend-only work, single-process apps, CRUD without async, beginner pattern questions. The skill declines below-threshold requests and answers simply instead.

## The workflow

```
/design  →  /contract  →  (your team writes code)  →  /review  →  /prelaunch
              ↓                                          ↑
        /architecture     /runbook ← any time, per incident type
```

Every artifact-writing command runs an automatic self-check before returning, so anti-patterns and consistency drift get caught in the same turn.

## What each command does

### `/design` — pick the patterns
Starting a new cross-service feature. Writes `design.md` (~60-80 lines) plus the per-feature README and a system-catalog row. **~1-2 min.**
```
/design payment-authorization Multi-tenant SaaS, PCI-DSS, p99 100/sec,
RTO 5 min. Owner: Payments Platform.
```

### `/contract` — define the wire format
After `/design`, for each channel the feature owns. Writes the schema (Avro/Protobuf/JSON Schema), the AsyncAPI 3.1 spec, and a ~40-line contract doc. Catches `additionalProperties: false` + BACKWARD traps. **~1-2 min per channel** (batchable).
```
/contract orders.placed.v1 Owner: Orders Platform. BACKWARD compat.
Per-(tenant_id, order_id) ordering.
```

### `/architecture` — record a durable decision
A non-trivial choice between alternatives (broker, workflow engine, mesh, schema-registry). Writes a Nygard ADR with system concerns, alternatives, rollout, risks. Feature-scoped or platform-scoped. **~2-3 min.**
```
/architecture ADR for Temporal vs Step Functions for the order-fulfillment saga.
```

### `/review` — architectural review of a diff
PR or diff review. Conversational findings (no file written): patterns touched, anti-patterns, 8-question reliability checklist, failure-mode walk, readiness tier. **~2-3 min.**
```
/review the changes in src/payments/
```

### `/runbook` — operational runbook
For each incident type the feature might face (DLQ triage, replay, schema rollback, region failover, saga-stuck). Includes safety warnings, triage, mitigation, verification, stop/rollback criteria. Feature- or platform-scoped. **~2-3 min.**
```
/runbook DLQ triage on orders.placed.v1.dlq. Owner: Orders Platform.
```

### `/prelaunch` — go/no-go decision
Pre-launch gate. Runs `/review`'s logic and writes a launch decision with mandatory rollback plan. **Defaults to NO-GO if any Critical findings exist.** **~3-5 min.**
```
/prelaunch order-fulfillment for v2.0
```

## What lands on disk

```
docs/
├── system/
│   ├── catalog.md             # registry, one row per feature
│   ├── adrs/                  # platform-wide ADRs
│   ├── runbooks/              # platform-wide runbooks
│   └── (optional) glossary.md, topology.md, capacity.md, compliance.md, dr.md
└── features/<slug>/
    ├── README.md              # per-feature index
    ├── design.md
    ├── adrs/
    ├── contracts/             # human-readable contract docs
    ├── schemas/               # Avro / Protobuf / JSON Schema
    ├── asyncapi/              # AsyncAPI 3.1 specs
    ├── runbooks/
    └── launches/              # GO/NO-GO decisions with rollback
```

Two clicks from `docs/system/catalog.md` to any artifact. Every doc has a `## Related artifacts` section linking siblings.

**Shared knowledge** (broker choice, channel naming, observability standard) lives under `docs/system/`. The rule: **reference, don't restate**. Per-feature READMEs link applicable platform docs rather than copy-paste them.

## Glossary

The skill uses distributed-systems vocabulary directly. Quick definitions for the most common terms:

### Artifacts the skill produces
- **Design doc** — patterns chosen, channel boundaries, system concerns. The "what and why" before code.
- **ADR (Architecture Decision Record)** — one durable decision in Nygard format: Status / Context / Decision / Consequences / Alternatives. Outlasts the code.
- **Contract** — wire-format definition for one channel: schema + AsyncAPI spec + human-readable doc.
- **Runbook** — step-by-step procedure for a paged engineer at 2 a.m. (DLQ triage, replay, region failover).
- **Launch decision** — pre-launch GO/NO-GO with blockers, acknowledged risks, and a mandatory rollback plan.

### Messaging
- **Channel** — a named stream that carries one event type, e.g. `orders.placed.v1`.
- **Broker** — message-passing infrastructure: Kafka, RabbitMQ, SQS/SNS, NATS, Pub/Sub.
- **DLQ (Dead Letter Queue)** — where messages land when they can't be processed.
- **Schema Registry** — central store of message schemas with compatibility enforcement on every change.
- **CloudEvents** — standard message envelope (`id`, `source`, `type`, `subject`, `time`, ...).
- **AsyncAPI** — OpenAPI-equivalent for async/event-driven APIs; the schema for your channels.
- **Saga / Process Manager** — multi-step business flow with explicit compensation steps when later stages fail.
- **Outbox** — atomic DB-write + publish via a transactional outbox table relayed to the broker.
- **Idempotent Receiver** — consumer that produces the same result whether a message arrives once or many times (deduplicates by event id).
- **CDC (Change Data Capture)** — stream of database row changes turned into events (Debezium, DynamoDB Streams).

### Schema evolution
- **BACKWARD compatibility** — new code can read old data. Adding optional fields is safe; closed schemas (`additionalProperties: false`) and closed enums break it.
- **FORWARD compatibility** — old code can read new data; new fields must be ignorable.
- **FULL compatibility** — both BACKWARD and FORWARD; the strictest mode.

### Anti-patterns
- **Dual-write** — writing to DB and publishing to a broker as separate steps. One can succeed while the other fails. Use Outbox + CDC instead.
- **Ack-before-commit** — acknowledging a message before its side-effects are persisted; loses messages on crash.
- **Retry storm** — multiple layers (client, mesh, broker, SDK) all retry independently, multiplying load on a degraded dependency.
- **Distributed monolith** — services that look independent but cannot deploy without coordinating with each other.
- **Distributed 2PC** — two-phase commit across services. Avoid. Use saga + compensation.

### Operations
- **Readiness tier** — maturity classification: **Prototype** (working but not safe to depend on) → **Service-ready** (one team can run it) → **Production-ready** (real users, real SLOs) → **Enterprise-critical** (DR, compliance, multi-region).
- **System concerns** — the layer beyond code: ownership, tenancy, compliance, cost, capacity, DR, lifecycle. Every artifact captures these.
- **Replay / Backfill** — reprocess historical messages to recover from a bug or catch up a new consumer.
- **Region failover** — promote a secondary region to primary after the primary fails. RPO/RTO are the data-loss / recovery-time targets.

For deeper definitions and modern realizations of each pattern, see [`reference/catalog.md`](reference/catalog.md) and [`reference/decision-tree.md`](reference/decision-tree.md).

## Install

**Plugin marketplace** (recommended):
```
/plugin marketplace add adibhanna/distributed-systems-patterns
/plugin install distributed-systems-patterns@adibhanna-distributed-systems-patterns
```

**Symlink** (Claude Code, Codex, OpenCode):
```bash
git clone https://github.com/adibhanna/distributed-systems-patterns ~/.agents/skills/distributed-systems-patterns
~/.agents/skills/distributed-systems-patterns/scripts/install.sh
```

## Reference

[`docs/getting-started.md`](docs/getting-started.md) — walkthrough with example prompts and timing baselines.

[`reference/`](reference/) — pattern catalog, decision tree, production checklists, failure modes, AWS/GCP/Azure mappings, schema migration. Loaded on demand by the agent.

## License

MIT. See [`LICENSE`](LICENSE).
