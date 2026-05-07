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
