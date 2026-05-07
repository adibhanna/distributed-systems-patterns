# Distributed Systems Patterns Skill

<p align="left">
  <img src="./logo.jpg" alt="Distributed Systems Patterns logo" width="600">
</p>

A Claude Code skill for **distributed-systems decisions**: design docs, message contracts, ADRs, runbooks, and launch decisions for event-driven, microservice, and integration work. Six slash commands produce durable architectural artifacts that link into a per-feature index and a system-level catalog.

The skill does **not** generate implementation code or tests — your team's existing dev environment, IDE, frameworks, and CI handle those better. The skill focuses on the layer where teams typically under-invest: decisions and reviews.

> **Heads up**: this is a heavy-duty toolkit for production systems with real cross-team coordination. If you're working alone, on a prototype, or on a single-process app, [skip ahead](#who-this-is-for) — you'll likely overengineer.

## Who this is for

Distributed-systems engineers, tech leads, staff/principal engineers, platform teams, and architects making **cross-service decisions at scale**. The skill earns its weight when:

- Multiple services or teams must agree on contracts and ownership.
- A change introduces durable infrastructure (broker, workflow engine, schema registry, mesh, cache fleet, shard, new consistency model).
- The work needs decision artifacts that outlast the code (ADRs that future hires can read; runbooks that on-call engineers reach for at 2 a.m.).

> **Do NOT use this for small projects.** Running the full pipeline on a side project, hackathon, class assignment, or scrappy MVP is overengineering theater. You'll produce ten markdown files for code that doesn't exist yet.

**Wrong fit**:
- Side projects, hobby code, hackathons, prototypes
- Single-process apps (one Flask/Express/FastAPI service + one DB)
- Frontend-only work
- CRUD apps without async work
- Single-team startups under ~10 engineers
- Single-function utilities (a script, a one-purpose Lambda)
- Beginner pattern questions ("what is a queue?")
- ETL pipelines without service coordination
- Internal tools with single-digit users

If your project doesn't fit the "earns its weight" list, the skill is overhead, not help. The skill is configured to **decline** below-threshold requests and answer simply instead.

## How to actually use it

A typical feature goes through these steps. Run commands as needed; skip what doesn't apply. Each artifact-writing command runs an automatic self-check before returning, so the agent catches anti-patterns and consistency drift in the same turn.

```
/design  →  /contract  →  (your team writes code)  →  /review  →  /prelaunch
              ↓                                          ↑
        /architecture     /runbook ← any time, per incident type
```

### 1. `/design` — pick the patterns

**When**: Starting a new cross-service feature, designing a new event flow, or redesigning an existing one.

**Input**: A short description of what you're building, owner, capacity, compliance, tenancy, DR requirements.

**Output**:
- `docs/features/<slug>/design.md` — patterns chosen, system concerns, channel boundaries (~60-80 lines)
- `docs/features/<slug>/README.md` — per-feature index
- `docs/system/catalog.md` — system registry row

**Self-check**: anti-patterns scanned, system concerns populated (no all-`<TBD>` blocks), cross-links resolve.

**Time**: ~1-2 min.

```text
/design payment-authorization Multi-tenant SaaS, PCI-DSS scope, p99
100 authorizations/sec, RTO 5 min. Owner: Payments Platform.
Triggered by orders.placed.v1; emits payments.authorized.v1.
```

### 2. `/contract` — define the wire format

**When**: After `/design`, for each event or command channel the feature owns. The schema locks in before code drift starts.

**Input**: Channel name, owner, producer/consumer list, ordering key, compatibility mode (BACKWARD/FORWARD/FULL).

**Output** (per channel):
- `docs/features/<slug>/schemas/<channel>.<ext>` — Avro / Protobuf / JSON Schema
- `docs/features/<slug>/asyncapi/<channel>.yaml` — AsyncAPI 3.1 spec
- `docs/features/<slug>/contracts/<channel>.md` — human-readable contract (~40 lines)

**Self-check**: catches `additionalProperties: false` + BACKWARD trap, closed-enum + BACKWARD trap, cross-channel consistency (expirytime, retention), channel name match across schema/asyncapi/contract files, ordering key matches the design.

**Time**: ~1-2 min per channel. Batch with `continue, and batch the remaining: <list>` if you have many channels.

```text
/contract orders.placed.v1 Owner: Orders Platform. Producer:
orders-service. Consumers: payments, inventory, notifications.
Per-(tenant_id, order_id) ordering. BACKWARD compat.
```

### 3. Your team writes the implementation

The skill **does not write code**. The design's `## Boundary contracts` section and the contract files are the inputs your team codes against. Use your team's IDE, code generation tools, and test frameworks — they're better at this than the skill would be.

If you want a quick pattern boundary snippet (the exact outbox INSERT, the dedup check) ask explicitly: `Show me a Go boundary snippet for the Idempotent Receiver pattern using these contracts.` The skill produces a minimal sample at the pattern boundary, in the repo's language, library-agnostic where possible.

### 4. `/review` — architectural review of the diff

**When**: PR or diff review before merging. Run on staged changes, recent commits, or a specific path.

**Input**: A pointer to what to review (the diff, a service path, or "the design and contracts").

**Output**: Conversational findings (no file written) covering:
- **Patterns touched** (Outbox, Process Manager, Idempotent Receiver, etc.)
- **Contracts affected** (schema changes, compatibility breaks, DLQ owner shifts)
- **Anti-patterns** (dual-write, ack-before-commit, unbounded retry, retry storm, distributed monolith)
- **8-question reliability checklist** with Answered/Open/Regressed grading
- **Distributed-systems checklist** (boundary, consistency, scaling, backpressure, multi-region)
- **Failure-mode walk** — top 3-5 likely failures with root cause + blast radius + mitigation + test
- **Readiness verdict** — current tier (Prototype / Service-ready / Production-ready / Enterprise-critical) with concrete gaps to the next tier

Findings categorized: **Critical** / **Important** / **Suggestion** / **System** (touches ownership, tenancy, compliance, cost, capacity, DR, lifecycle).

**Time**: ~2-3 min.

```text
/review the changes in src/payments/
```

```text
/review the order-fulfillment design and contracts. No implementation
exists yet.
```

### 5. `/architecture` — record a durable decision

**When**: A non-trivial choice between alternatives that should outlast the code (broker selection, workflow-engine choice, mesh policy, schema-registry vendor, multi-region strategy).

**Input**: The decision being made, the alternatives considered, the trade-offs.

**Output**:
- `docs/features/<slug>/adrs/NNNN-<title>.md` — feature-scoped ADR (saga orchestrator for THIS service)
- `docs/system/adrs/NNNN-<title>.md` — platform-wide ADR (broker choice, mesh policy)

ADR follows Nygard format (Status / Context / Decision / Consequences / Alternatives) plus Summary + System concerns + Trade-offs explicit + Rollout + Risks + Related artifacts.

**Time**: ~2-3 min.

```text
/architecture ADR for choosing Temporal over Step Functions for the
order-fulfillment saga. Alternatives: Step Functions Standard,
event choreography (no orchestrator), Camunda 8.
```

### 6. `/runbook` — operational runbook

**When**: For each incident type a feature might face. Run as you encounter the need.

**Common types**: DLQ triage, replay/backfill, schema rollback, region failover, saga-stuck, broker outage.

**Output**:
- `docs/features/<slug>/runbooks/<incident>.md` — feature-scoped (DLQ for THIS channel)
- `docs/system/runbooks/<incident>.md` — platform-scoped (broker outage, region failover)

Includes: Summary + System concerns + Owner/escalation + Safety warnings + Triage steps + Mitigation + Verification + Stop/rollback criteria + Audit trail + Post-incident actions.

**Time**: ~2-3 min.

```text
/runbook for DLQ triage on orders.placed.v1.dlq. Owner: Orders Platform.
Page-target: orders-platform-oncall.
```

### 7. `/prelaunch` — go/no-go decision

**When**: Before a production launch, after `/review` flagged blockers (or to confirm there are none).

**Input**: The feature/slug being launched.

**Output**: `docs/features/<slug>/launches/<YYYY-MM-DD>.md` with Status (GO/NO-GO), tier achieved, blockers, recommended fixes, acknowledged risks, and a **mandatory rollback plan** (trigger conditions + procedure + RTO).

The command runs `/review`'s logic and **defaults to NO-GO if any Critical findings exist**. You must explicitly accept the risks to override.

**Time**: ~3-5 min.

```text
/prelaunch order-fulfillment for v2.0
```

## Quick reference

| Command | When | Time | Writes? |
| --- | --- | --- | --- |
| `/design` | Starting a new feature | ~1-2 min | yes |
| `/contract` | Defining a wire format | ~1-2 min/channel | yes (3 files/channel) |
| `/architecture` | Recording a durable decision | ~2-3 min | yes |
| `/review` | Reviewing a diff or design | ~2-3 min | no (chat) |
| `/runbook` | Documenting an incident response | ~2-3 min | yes |
| `/prelaunch` | Pre-launch go/no-go | ~3-5 min | yes |

## What lands on disk

```
docs/
├── system/
│   ├── catalog.md             # service registry, one row per feature
│   ├── adrs/                  # platform-wide ADRs
│   ├── runbooks/              # platform-wide runbooks
│   └── (optional) glossary.md, topology.md, capacity.md, compliance.md, dr.md
└── features/<slug>/
    ├── README.md              # per-feature index (auto-updated)
    ├── design.md              # patterns, system concerns
    ├── adrs/                  # feature-scoped ADRs
    ├── contracts/             # human-readable contract docs
    ├── schemas/               # Avro / Protobuf / JSON Schema
    ├── asyncapi/              # AsyncAPI 3.1 specs
    ├── runbooks/              # feature-scoped runbooks
    └── launches/              # GO/NO-GO decisions with rollback
```

Implementation source and tests live wherever your team's dev environment puts them.

**Reader navigation**: `docs/system/catalog.md` → `docs/features/<slug>/README.md` → any artifact. Two clicks from "the system" to a specific channel's runbook. Every artifact has a `## Related artifacts` section linking peers; every per-feature README has a `## Shared references` section linking to applicable platform docs.

## Shared knowledge across features

Some knowledge applies to every feature: the broker the platform uses, the channel-naming convention, the observability standard, the on-call topology. Restating it in every feature design is duplication waiting to drift. The skill keeps it under `docs/system/`:

| Layer | Location | Examples |
| --- | --- | --- |
| Service registry | `docs/system/catalog.md` | One row per feature |
| Platform-wide ADRs | `docs/system/adrs/` | Broker choice, mesh policy |
| Platform runbooks | `docs/system/runbooks/` | Broker outage, region failover |
| Glossary, topology, capacity, compliance, DR | `docs/system/*.md` | Hand-authored when relevant |

**The rule: reference, don't restate.** Each per-feature README has a `## Shared references` section linking applicable platform docs. Cross-link from a feature artifact to a shared doc with `../../system/<path>`.

Use `/architecture` with platform scope for cross-feature ADRs. Use `/runbook` with platform scope for cross-feature incidents.

## Install

### Option A — Plugin marketplace (recommended)

```text
/plugin marketplace add adibhanna/distributed-systems-patterns
/plugin install distributed-systems-patterns@adibhanna-distributed-systems-patterns
```

Claude Code discovers the skill and all 6 commands automatically.

### Option B — Symlink install (Claude Code, Codex, OpenCode)

```bash
git clone https://github.com/adibhanna/distributed-systems-patterns ~/.agents/skills/distributed-systems-patterns
~/.agents/skills/distributed-systems-patterns/scripts/install.sh
```

Detects Claude Code, Codex, and OpenCode and creates idempotent symlinks. Use `--all` to install for every supported tool, `--dry-run` to preview.

Verify:

```bash
bash ~/.agents/skills/distributed-systems-patterns/scripts/validate_skill.sh
```

For per-tool detail (Cursor, Aider, OpenCode project-relative installs), see [`docs/`](docs/).

## Reference

Detailed walkthrough with example prompts and timing baselines: [`docs/getting-started.md`](docs/getting-started.md).

Pattern catalog and decision tree (when the agent needs more depth than memory):
- [`reference/catalog.md`](reference/catalog.md) — pattern names → modern realizations
- [`reference/decision-tree.md`](reference/decision-tree.md) — problem → pattern lookup
- [`reference/checklist.md`](reference/checklist.md) — production review gates
- [`reference/failure-modes.md`](reference/failure-modes.md) — failure catalog and mitigations
- [`reference/architecture-documentation.md`](reference/architecture-documentation.md) — RFC / ADR / migration plan templates

The full `reference/` directory has 27 files covering AWS/GCP/Azure mappings, security and compliance, schema migration, cost and FinOps, gRPC, LLM workflows, and language-specific pointers. Agents load only what's needed for the task.

## License

MIT. See [`LICENSE`](LICENSE).
