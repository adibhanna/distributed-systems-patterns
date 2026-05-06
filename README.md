# Distributed Systems Patterns Skill

<p align="left">
  <img src="./logo.jpg" alt="Distributed Systems Patterns logo" width="600">
</p>

A connected system for designing distributed systems **at scale**. Produces design docs, ADRs, RFCs, message contracts, runbooks, readiness assessments, and launch decisions that link into a per-feature index and a system-level catalog. Covers integration patterns plus the layer beyond code: team ownership and Conway boundaries, multi-tenancy, cost ownership, compliance, capacity, disaster recovery, and lifecycle. Default outputs are architectural artifacts; specific library choices stay with the team.

## Who this is for

Distributed-systems engineers, tech leads, staff/principal engineers, platform teams, and architects making cross-service decisions at scale. The artifacts the skill produces (design docs, ADRs, contracts, runbooks, launch decisions) are valuable when multiple teams or services must coordinate.

**Not for**:

- Single-process applications or single-function utilities
- Frontend-only work
- Quick local refactors or single-function code
- ETL jobs or scripts without service coordination
- Beginner-level pattern questions ("what is a queue?")
- Pre-MVP prototypes that don't yet have users or operational costs

**Threshold for invoking the full pipeline**: at least two services or two teams must coordinate; or the work introduces a broker, workflow engine, schema, mesh, cache, shard, or new consistency model; or the request explicitly asks for an ADR / RFC / runbook / launch decision. If none of these apply, this skill is overkill — a regular prompt without the slash commands is faster and clearer.

## Install

### Option A — Claude Code plugin marketplace (recommended)

```text
/plugin marketplace add adibhanna/distributed-systems-patterns
/plugin install distributed-systems-patterns@adibhanna-distributed-systems-patterns
```

Claude Code discovers the skill and all 9 slash commands automatically.

### Option B — One-command symlink install (Claude Code, Codex, OpenCode)

```bash
git clone https://github.com/adibhanna/distributed-systems-patterns ~/.agents/skills/distributed-systems-patterns
~/.agents/skills/distributed-systems-patterns/scripts/install.sh
```

Detects Claude Code, Codex, and OpenCode and creates idempotent symlinks for both the skill and the slash commands. Use `--all` to install for every supported tool, `--dry-run` to preview.

Verify:

```bash
bash ~/.agents/skills/distributed-systems-patterns/scripts/validate_skill.sh
```

`validate_skill.sh` runs locally with `python3` only (no Ruby, no ripgrep), and CI runs the same validator on every push.

## Slash commands

Once installed, these commands invoke the skill in opinionated ways:

| Command | Role in the system | Writes? |
| --- | --- | --- |
| `/design` | Pick patterns and boundaries; service-level design with system concerns | yes (`docs/features/<slug>/design.md`) |
| `/contract` | Define wire contract: schemas, AsyncAPI, owner | yes (3 files under `docs/features/<slug>/`) |
| `/architecture` | ADR / RFC / Implementation Plan, feature-scoped or platform-wide | yes (feature or `docs/system/`) |
| `/standard` | Platform convention every feature follows | yes (`docs/system/standards/<topic>.md`) |
| `/runbook` | Operational runbook, feature-scoped or platform-wide | yes (feature or `docs/system/runbooks/`) |
| `/review` | Architectural review of a diff | no (chat) |
| `/failure-mode` | Per-failure blast radius across tenants, compliance, cost, DR | no (chat) |
| `/readiness` | Map a service or change to a readiness tier | no (chat) |
| `/ship` | Fan-out: review + failure-mode + readiness, GO/NO-GO with rollback | yes (`docs/features/<slug>/launches/<date>.md`) |

When loaded via the plugin marketplace, commands are namespaced as `/distributed-systems-patterns:<name>`.

For a full walkthrough — install verification, a cold-start prompt, and the order-fulfillment scenario chained through every command — see [`docs/getting-started.md`](docs/getting-started.md).

## How it connects

The skill produces three layers of artifacts that link together:

1. **Per-feature folders** at `docs/features/<slug>/`. Each feature owns one folder containing all its artifacts: `design.md`, `README.md`, `adrs/`, `contracts/`, `schemas/`, `asyncapi/`, `runbooks/`, `launches/`. Cross-links inside a feature are sibling/child paths, not `../../...` traversals.
2. **A per-feature index** at `docs/features/<slug>/README.md`. Aggregates every artifact for one feature plus its ownership, tenancy, cost owner, compliance class, capacity, DR posture, and lifecycle. Auto-updated by every command.
3. **A system catalog** at `docs/system/catalog.md`. One row per feature: owner, tier, SLO, compliance, last reviewed. Auto-updated whenever a per-feature README changes. Platform-wide ADRs live alongside it under `docs/system/adrs/`.

Reader navigation:

```text
docs/system/catalog.md
  -> docs/features/<slug>/README.md
    -> docs/features/<slug>/design.md
       docs/features/<slug>/adrs/NNNN-<title>.md
       docs/features/<slug>/contracts/<channel>.md
       docs/features/<slug>/runbooks/<incident>.md
       docs/features/<slug>/launches/<date>.md
```

Two clicks from "the system" to "this consumer's DLQ runbook".

### Path conventions

- **Slug**: feature/service identifier in kebab-case (e.g. `order-fulfillment`). All artifacts for one feature live under `docs/features/<slug>/`.
- **Channel**: event/message channel name in dotted form (e.g. `orders.placed.v1`). Used as the filename for contracts, schemas, AsyncAPI specs.
- **ADR scope**: feature-scoped ADRs (most ADRs, e.g. saga orchestrator for THIS feature) live at `docs/features/<slug>/adrs/`. Platform-wide ADRs (broker choice, mesh policy) live at `docs/system/adrs/`. The `/architecture` command asks which when ambiguous.
- **NNNN numbering**: per-folder. Feature-scoped ADR-0001 in one feature does not collide with feature-scoped ADR-0001 in another. Platform-wide ADRs use a separate sequence under `docs/system/adrs/`.

### Lifecycle

```mermaid
flowchart LR
    A[Strategy / problem framing] --> B[/design: pick patterns,<br/>boundaries, contracts/]
    B --> C[/contract: schemas,<br/>AsyncAPI, ownership/]
    B --> D[/architecture: ADRs,<br/>RFCs, plans/]
    C --> E[Implementation]
    D --> E
    E --> F[/review: architectural<br/>diff review/]
    F --> G[/failure-mode: blast radius,<br/>tenant impact/]
    G --> H[/readiness: tier and<br/>system-concerns evidence/]
    H --> I[/ship: GO/NO-GO<br/>with rollback/]
    I --> J[Operate: /runbook<br/>for each incident type]
    J --> K[Migrate / deprecate /<br/>retire]
    K --> A
```

Every command updates the per-feature README and the system catalog. The lifecycle is a loop, not a line.

### "Everything beyond code"

Each artifact carries a `## System concerns` block covering:

- **Owner team and Conway boundary**
- **Tenancy** (single-tenant or multi-tenant with specified isolation)
- **Compliance** (PII, GDPR, SOC2, PCI, data residency)
- **Cost owner** (team / cost center / per-event budget)
- **Capacity** (expected volume; growth assumption)
- **DR posture** (RPO, RTO, region strategy)
- **Lifecycle** (creation, deprecation trigger, replacement plan)

Unknown fields stay as `<TBD>` rather than being omitted - the placeholder forces the question.

## Shared knowledge across features

Some knowledge applies to every feature: the broker the platform uses, the channel-naming convention, the observability standard, the on-call topology, the compliance baseline. Restating it in every feature design is duplication waiting to drift. The skill keeps it in one place under `docs/system/`:

| Layer | Location | Examples |
| --- | --- | --- |
| Service registry | `docs/system/catalog.md` | One row per feature |
| Platform-wide ADRs | `docs/system/adrs/` | Broker choice, mesh policy, schema-registry vendor |
| Platform-wide runbooks | `docs/system/runbooks/` | Broker outage, schema-registry rollback, region-wide failover |
| Standards / conventions | `docs/system/standards/` | Channel-naming, observability, security baseline, deployment |
| Glossary | `docs/system/glossary.md` | Shared domain terms |
| Topology | `docs/system/topology.md` | Team ownership map and Conway boundaries |
| Capacity | `docs/system/capacity.md` | Platform capacity envelope |
| Compliance | `docs/system/compliance.md` | PII / GDPR / SOC2 baseline |
| DR | `docs/system/dr.md` | Region failover plan |

**The rule: reference, don't restate.** When a feature design touches a shared concern, link to the shared doc rather than copy-pasting the rule. If the same fact appears in three feature docs, it belongs in `docs/system/standards/` instead.

### Commands that write shared knowledge

- `/standard <topic>` - writes a platform convention to `docs/system/standards/<topic>.md`. Examples: `/standard observability`, `/standard channel-naming`, `/standard security-baseline`.
- `/architecture` (with platform-wide scope) - writes a platform-wide ADR to `docs/system/adrs/`.
- `/runbook` (with platform-wide scope) - writes a platform runbook to `docs/system/runbooks/`.

The optional top-level docs (`glossary.md`, `topology.md`, etc.) are user-created or asked for explicitly. The skill does not auto-generate them, but every feature artifact the skill writes will reference them when they exist.

### How features link in

Each per-feature README at `docs/features/<slug>/README.md` carries a `## Shared references` section listing which platform docs apply to that feature. Cross-link math: from a feature artifact to a shared doc is `../../system/<path>` (one `..` for the feature subdir, one for `features/`). The README aggregates links so a reader can navigate from one feature to its applicable platform standards in one click.

## Manual install (per-tool detail)

- Claude Code - `~/.claude/skills/distributed-systems-patterns` skill + `~/.claude/commands/distributed-systems-patterns/` commands. See [`docs/claude-code-setup.md`](docs/claude-code-setup.md).
- Codex CLI - activation block appended to `~/.codex/AGENTS.md`. See [`docs/codex-setup.md`](docs/codex-setup.md).
- OpenCode - `~/.config/opencode/skills/distributed-systems-patterns` symlink, or per-project. See [`docs/any-agent-setup.md`](docs/any-agent-setup.md).
- Cursor - per-repo project rule under `.cursor/rules/`. Not auto-installed. See [`docs/cursor-setup.md`](docs/cursor-setup.md).

It combines modern integration, messaging, event-driven architecture, workflow, distributed systems, platform engineering, and enterprise operations guidance: Kafka/Redpanda, RabbitMQ, SQS/SNS/EventBridge, Pub/Sub, Service Bus/Event Grid, NATS, Pulsar, Debezium, CloudEvents, AsyncAPI, Schema Registry, OpenTelemetry, Temporal, Step Functions, Camunda, Kubernetes, KEDA, service mesh, Envoy, Dapr, caching, sharding, multi-region, SLOs, and enterprise governance. Code examples in the reference files are illustrative; the skill recommends tool categories, not specific packages.

## What the skill makes agents do

When activated, the agent must:

1. Name the integration, distributed-systems, resilience, workflow, and architecture pattern(s) in play.
2. Answer the 8 reliability questions before coding or approving code.
3. Answer distributed-systems questions when the risk is service boundaries, scale, consistency, resilience, multi-region, or enterprise operations.
4. Flag anti-patterns such as dual-write, missing idempotency, unbounded retries, ack-before-commit, DLQs with no owner, distributed monoliths, retry storms, and unbounded queues.
5. Map the pattern to modern tooling.
6. Default to architectural artifacts (decisions, contracts, runbooks); show code only when explicitly asked, in the repo's language, library-agnostic where possible.
7. Add pattern comments in integration code, for example `// Pattern: Transactional Outbox - avoids dual-write`.
8. Use the review checklist before calling a change production-ready.
9. Maintain a per-feature index at `docs/features/<slug>/README.md` and a system catalog at `docs/system/catalog.md`. Every artifact updates both, so the system stays navigable.

## Layout

```text
skill/
├── README.md
├── SKILL.md                         # canonical skill with YAML frontmatter
├── AGENTS.md                        # cross-tool entry point for Codex/OpenCode/Aider/etc.
├── CHANGELOG.md                     # version history
├── skill.schema.json                # skill metadata schema
├── .gitignore
├── .github/
│   └── workflows/
│       └── validate.yml             # CI validation workflow
├── agents/
│   └── openai.yaml                  # OpenAI/Codex UI metadata
├── reference/
│   ├── catalog.md                   # systems and messaging pattern catalog
│   ├── agent-workflow.md            # agent lifecycle and output templates
│   ├── architecture-documentation.md # design docs, RFCs, ADRs, migration plans
│   ├── architecture-examples.md      # filled ADR/RFC examples
│   ├── aws-service-mapping.md       # AWS services mapped to system design concepts
│   ├── checklist.md                 # production review gates
│   ├── cost-and-finops.md           # cost ownership, FinOps, and budgeting
│   ├── decision-tree.md             # problem -> pattern lookup
│   ├── distributed-systems-guide.md # scale, resilience, boundaries, multi-region
│   ├── evaluation-prompts.md        # prompts to test skill behavior
│   ├── failure-modes.md             # failure catalog and mitigations
│   ├── go-examples.md               # Go producer/consumer/workflow snippets
│   ├── go-implementation-patterns.md # Go resilience/concurrency patterns
│   ├── grpc-streaming.md            # gRPC streaming patterns
│   ├── llm-workflow-patterns.md     # LLM workflow and orchestration patterns
│   ├── maturity-model.md            # maturity levels and next steps
│   ├── message-contract-template.md # CloudEvents + AsyncAPI starter
│   ├── modern-integration-field-guide.md # modern event-driven architecture guidance
│   ├── non-go-pointers.md           # Java/TypeScript/Python pointers
│   ├── operational-runbooks.md      # incident/runbook templates
│   ├── platform-service-mapping.md  # GCP/Azure/open-source mapping
│   ├── production-guide.md          # ownership, SLOs, runbooks, platform choice
│   ├── scenario-playbooks.md        # common end-to-end architectures
│   ├── schema-migration.md          # schema evolution and migration playbooks
│   ├── security-compliance.md       # PII, IAM, tenancy, webhooks, audit
│   ├── testing-strategy.md          # contract/replay/failure/load tests
│   └── webhook-security-go.md       # Go webhook signature verification
├── scripts/
│   ├── validate_skill.sh            # local package validation
│   └── migrate-layout.sh            # v0.2 -> v0.3 layout migration
└── docs/
    ├── system/
    │   ├── catalog.md
    │   ├── adrs/                          # platform-wide ADRs
    │   ├── runbooks/                      # platform-wide runbooks
    │   ├── standards/                     # conventions all features follow
    │   │   └── <topic>.md
    │   ├── glossary.md                    # optional
    │   ├── topology.md                    # optional
    │   ├── capacity.md                    # optional
    │   ├── compliance.md                  # optional
    │   └── dr.md                          # optional
    ├── features/
    │   └── <slug>/
    │       ├── README.md
    │       ├── design.md
    │       ├── adrs/
    │       ├── contracts/
    │       ├── schemas/
    │       ├── asyncapi/
    │       ├── runbooks/
    │       └── launches/
    ├── any-agent-setup.md
    ├── claude-code-setup.md
    ├── codex-setup.md
    ├── cursor-setup.md
    └── getting-started.md
```

`SKILL.md` is the canonical skill. `AGENTS.md` mirrors the activation policy and hard rules for tools that load `AGENTS.md`. The `reference/` directory is progressive disclosure: agents load only the file needed for the current task.

## Example prompt

```text
Use the distributed-systems-patterns skill to design an order-created event flow in Go.
Use Postgres, Kafka, CloudEvents, AsyncAPI, OpenTelemetry, and a DLQ.
Show the reliability checklist answers before code.
```

Expected shape of the answer:

```text
Patterns: Event Message + Datatype Channel + Transactional Outbox + Idempotent Receiver
Reliability: at-least-once, dedupe by CloudEvents id in Redis, per-order ordering, ...
Anti-patterns: direct DB commit followed by kafka send would be a dual-write
Modern realization: Postgres outbox + Debezium -> Kafka, CloudEvents, AsyncAPI, OTel
Implementation: Go snippets with pattern comments
Verification: checklist + tests
```

## Reference guide

- [`reference/catalog.md`](reference/catalog.md) - look up a named pattern and modern tool choices.
- [`reference/agent-workflow.md`](reference/agent-workflow.md) - lifecycle, review templates, and agent behavior rules.
- [`reference/architecture-documentation.md`](reference/architecture-documentation.md) - architecture docs, RFCs, ADRs, implementation plans, migration plans, and review rubrics.
- [`reference/architecture-examples.md`](reference/architecture-examples.md) - filled ADR/RFC examples for common decisions.
- [`reference/distributed-systems-guide.md`](reference/distributed-systems-guide.md) - distributed systems, enterprise scaling, resilience, service boundaries, and governance.
- [`reference/modern-integration-field-guide.md`](reference/modern-integration-field-guide.md) - modern event-driven architecture guidance.
- [`reference/aws-service-mapping.md`](reference/aws-service-mapping.md) - AWS service mapping while keeping the skill cloud-neutral.
- [`reference/platform-service-mapping.md`](reference/platform-service-mapping.md) - GCP, Azure, Kafka/RabbitMQ/NATS/Pulsar, and cloud-neutral mapping.
- [`reference/scenario-playbooks.md`](reference/scenario-playbooks.md) - ready-to-adapt architectures for common scenarios.
- [`reference/failure-modes.md`](reference/failure-modes.md) - failure catalog for design reviews and incidents.
- [`reference/testing-strategy.md`](reference/testing-strategy.md) - test strategy for distributed systems and messaging.
- [`reference/security-compliance.md`](reference/security-compliance.md) - security, PII, tenant isolation, webhook, and audit guidance.
- [`reference/operational-runbooks.md`](reference/operational-runbooks.md) - DLQ, replay, lag, schema rollback, workflow, and failover runbooks.
- [`reference/maturity-model.md`](reference/maturity-model.md) - team/platform maturity assessment and next steps.
- [`reference/evaluation-prompts.md`](reference/evaluation-prompts.md) - prompts to validate skill behavior.
- [`reference/decision-tree.md`](reference/decision-tree.md) - start here when the problem is known but the pattern is not.
- [`reference/checklist.md`](reference/checklist.md) - use before merge or production-readiness claims.
- [`reference/go-examples.md`](reference/go-examples.md) - Go snippets for outbox, idempotent consumer, DLQ, retry, and Temporal Process Manager.
- [`reference/go-implementation-patterns.md`](reference/go-implementation-patterns.md) - Go worker, timeout, idempotency, shutdown, and workflow patterns.
- [`reference/message-contract-template.md`](reference/message-contract-template.md) - CloudEvents and AsyncAPI starter for new channels.
- [`reference/production-guide.md`](reference/production-guide.md) - enterprise ownership, SLO, runbook, platform, and security guidance.
- [`reference/webhook-security-go.md`](reference/webhook-security-go.md) - webhook signature verification, timestamp windows, replay-window dedup, Go example.
- [`reference/schema-migration.md`](reference/schema-migration.md) - concrete walkthrough for adding/renaming/removing event-contract fields without breaking consumers.
- [`reference/cost-and-finops.md`](reference/cost-and-finops.md) - cost-aware operation: retention, per-event pricing, cross-region egress, queue depth vs spend.
- [`reference/grpc-streaming.md`](reference/grpc-streaming.md) - gRPC server-streaming, bidirectional streams, deadlines, retry interceptors, status codes.
- [`reference/llm-workflow-patterns.md`](reference/llm-workflow-patterns.md) - async LLM inference queueing, bounded retry, model-output validation, streaming token handoff.
- [`reference/non-go-pointers.md`](reference/non-go-pointers.md) - minimal pointers for Java/Spring Cloud Stream, TypeScript/NestJS, Python/FastAPI consumers.

## Maintenance

When changing the skill:

1. Update `SKILL.md` first.
2. Keep `AGENTS.md` aligned with activation rules, mandatory process, code rules, and references.
3. Keep `agents/openai.yaml` aligned with the skill name and user-facing description.
4. Keep large examples in `reference/`, not in `SKILL.md`.
5. Prefer Go examples.
6. Check for stale references to non-Go default examples or single-tool assumptions.
7. Run `bash scripts/validate_skill.sh` and ensure CI workflow `.github/workflows/validate.yml` passes.

Run local validation:

```bash
./scripts/validate_skill.sh
```

## License

MIT. See [`LICENSE`](LICENSE).

## Scope

This is a practical pattern language and agent workflow for distributed systems and enterprise-scale service design. It helps AI coding agents apply shared vocabulary, reliability questions, scale/resilience checks, anti-pattern gates, and modern implementation defaults during day-to-day engineering work.
