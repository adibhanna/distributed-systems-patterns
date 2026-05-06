# Getting Started

A walkthrough of `distributed-systems-patterns` from install to shipping a real change. Uses the order-fulfillment scenario throughout so the commands chain naturally.

## 1. Verify the install

After running `scripts/install.sh`, check that your tool found the skill:

**Claude Code**: type `/` in the prompt. You should see commands prefixed `distributed-systems-patterns:*`. The skill itself appears in the skills list — search for it by name.

**Codex / OpenCode / Cursor**: see [`codex-setup.md`](codex-setup.md), [`any-agent-setup.md`](any-agent-setup.md), [`cursor-setup.md`](cursor-setup.md).

If nothing shows up, run:

```bash
bash ~/.agents/skills/distributed-systems-patterns/scripts/validate_skill.sh
```

A green run means the skill files are valid; a red run names what's wrong.

## 2. Cold-start vs. command — when to use which

**Commands write files** for structured deliverables (design docs, ADRs, contract schemas, runbooks, launch decisions). Use `/design`, `/architecture`, `/contract`, `/runbook`, `/ship` whenever you want a persistent artifact in the repo.

**Cold-start prompts give you guidance in chat.** The skill auto-activates on distributed-systems vocabulary and walks the patterns + reliability checklist + decisions, but does not save anything to disk unless you ask. Use cold-start when you're exploring or want to think out loud.

Cold-start example:

```text
Design an order-placed event flow. Postgres for the source of truth, Kafka
for the event stream, CloudEvents envelope, AsyncAPI for the contract,
OpenTelemetry for trace context, DLQ for poison messages. Walk the
reliability checklist before sketching the implementation.
```

If you want a persistent design doc instead of chat output, use `/design` with the same description — the command writes to `docs/designs/<slug>-design.md` and emits a one-line confirmation. The cold-start prompt is for thinking out loud; commands are for deliverables.

Expected response shape (from `SKILL.md`'s mandatory contract):

```text
Patterns: Event Message + Datatype Channel + Transactional Outbox + Idempotent Receiver
Reliability:
- Delivery: at-least-once
- Idempotency: dedupe by CloudEvents id in inbox table, retained 30 days
- Bad messages: orders.placed.v1.dlq, owned by Orders Platform
- Retry: 5 attempts, exponential backoff + jitter
- Ordering: per order_id (Kafka partition key)
- Schema: Avro/Protobuf in Schema Registry, BACKWARD compatibility CI
- Observability: traceparent + lag/age/DLQ/retry metrics
- Failure boundary: local transaction only; fulfillment saga handles downstream

Anti-patterns: db.save() then broker.publish() would be a dual-write
Modern realization: Postgres outbox + Debezium -> Kafka, CloudEvents 1.0.2,
                    AsyncAPI 3.1, OpenTelemetry W3C Trace Context
Decisions: pattern map, channel/ordering/idempotency-key choices, owner, retention
Boundary contracts: CloudEvents envelope fields, AsyncAPI channel, schema compatibility mode
Implementation outline: file inventory of producers/consumers/migrations to write — not inline code
Verification: 8-question checklist + tests (idempotency, DLQ, replay)
```

If the agent goes straight to code without naming patterns or running the checklist, the skill didn't activate. Force it:

```text
Use the distributed-systems-patterns skill: design an order-placed event flow in Go.
```

### A connected system, not eight standalone commands

Every artifact the skill writes lands in two places: the conventional path (`docs/designs/...`, `docs/contracts/...`, etc.) AND the per-service index at `docs/services/<slug>/README.md`. The per-service index aggregates every artifact for one service plus its ownership, tenancy, cost owner, compliance class, capacity, DR posture, and lifecycle. The system catalog at `docs/system/catalog.md` indexes every service.

Reader navigation:

```text
docs/system/catalog.md
  -> docs/services/<slug>/README.md
    -> docs/designs/<slug>-design.md
       docs/contracts/<channel>.md
       docs/runbooks/<incident>.md
       docs/adr/NNNN-<slug>.md
       docs/launches/<slug>-<date>.md
```

Two clicks from "the system" to "this channel's runbook".

### Everything beyond code

Each artifact carries a `## System concerns` block covering owner team, tenancy, cost owner, compliance, capacity, DR posture, and lifecycle. Unknown fields stay as `<TBD>` so the question is forced. The skill is for the layer beyond code: org topology, tenant isolation, compliance lineage, capacity, cost ownership, DR, deprecation - alongside the patterns and contracts.

If you want code, ask for it explicitly: "Show me a Go boundary snippet for the idempotent receiver." The skill produces a minimal, library-agnostic sample at the pattern boundary, not a full production handler.

## 3. Walkthrough: shipping order fulfillment

A complete journey — pick patterns, define contracts, implement, review, ship. Each step uses one slash command.

### Step 1 — `/design` — pick the patterns

Type:

```text
/design Build an order-fulfillment system. Orders API writes to Postgres.
Downstream services: payments, inventory, shipping, notifications. Need a
saga that survives partial failures and supports compensation. Owner:
Orders Platform team. Multi-tenant with tenant_id partitioning. Capacity:
1k orders/sec p99. PCI in scope (cards never enter our pipeline).
```

The command:

- Writes `docs/designs/order-fulfillment-design.md` with `## Summary` (status, date, TL;DR), `## System concerns` (owner, tenancy, compliance, cost, capacity, DR, lifecycle — `<TBD>` for unknowns), pattern map, 8-question reliability checklist, distributed-systems checklist, modern-realization mapping (a CDC tool, a Kafka-compatible broker, a workflow engine — categories, not specific packages unless you ask), boundary contracts at the conceptual level, file/component plan, open questions, readiness tier.
- Creates or updates `docs/services/order-fulfillment/README.md` (per-service index) with the design link and the system-concerns block.
- Creates or updates `docs/system/catalog.md` (top-level registry) with one row for the service.
- Emits a one-line confirmation in chat: `Design written to docs/designs/order-fulfillment-design.md` plus the updated index/catalog paths.

### Step 2 — `/contract` — define `orders.placed.v1`

Type:

```text
/contract Design the orders.placed.v1 contract. Owner: Orders Platform team.
Producers: orders-service. Consumers: payments-service, inventory-service,
notifications-service. Required fields: order_id, customer_id, total_cents,
items[]. Need per-order ordering.
```

The command writes three files:

- `schemas/orders.placed.v1.json` — payload schema (Avro/Protobuf/JSON Schema).
- `asyncapi/orders.placed.v1.yaml` — AsyncAPI 3.1 channel + operation + message.
- `docs/contracts/orders.placed.v1.md` — human-readable contract with `## Summary` (status, date, channel, owner, TL;DR), `## System concerns` (compliance class, retention, cost), CloudEvents 1.0.2 envelope example, compatibility mode (BACKWARD by default), versioning policy (when v2 is required), DLQ owner, replay/redrive policy, and `## Related artifacts` linking back to the design.

It also updates `docs/services/order-fulfillment/README.md` (adds the channel to "Channels owned" and the contract to "Artifacts") and `docs/system/catalog.md` (refreshes the service row).

Confirmation in chat: `Contract orders.placed.v1 written: schemas/..., asyncapi/..., docs/contracts/...`

### Step 3 — Implementation lives outside the skill

The skill produces decisions, contracts, and operational artifacts. It does **not** produce production handlers by default. Implementation is your engineering team's work — once the design and contract have landed, the file/component plan in the design doc tells your team which source files to write.

If you want a small boundary snippet to anchor the team (e.g. the exact outbox INSERT, the dedup check, the retry classifier), ask explicitly:

```text
Show me a boundary snippet for the Transactional Outbox INSERT, in the
language of this repo. Library-agnostic where possible.
```

The skill returns a minimal sample at the pattern boundary (one comment line: `// Pattern: Transactional Outbox`), in the repo's language if one is detected. Specific package picks (which Postgres driver, which CDC tool) stay with your team — the skill recommends categories, not packages, unless you ask.

### Step 4 — `/review` — architectural review

After your team writes the consumer, run:

```text
/review the inventory consumer in src/inventory/consumer.go and src/inventory/inbox.go
```

This is **architectural review**, not line-by-line code review. The command identifies which patterns the change touches, which contracts it affects, which anti-patterns it introduces, and which reliability + system-concerns evidence it answers or leaves open.

- Patterns touched: Outbox? Process Manager? Idempotent Receiver? Circuit Breaker?
- Contracts affected: new channel? schema change? compatibility break? DLQ owner shift?
- 8-question reliability checklist walked: each question marked Answered, Open, or Regressed.
- System concerns walked: ownership change? tenancy boundary? cost owner? compliance class? capacity envelope? DR posture?
- Anti-patterns: dual-write, ack-before-commit, unbounded retry, retry storm, distributed monolith, missing trace context.
- Readiness-tier impact: does the change move the service up, down, or sideways?

Findings categorize as **Critical** (launch-blocking anti-pattern or contract break), **Important** (reliability regression or contract weakening), **Suggestion** (architecture tightening), or **System** (touches ownership, tenancy, compliance, cost, capacity, DR, or lifecycle). Conversational output — not a file. If material new System facts emerge, the command suggests updating `docs/services/<slug>/README.md`.

Output shape:

```markdown
## Findings

### Critical
- src/inventory/consumer.go:142 — ack-before-commit. Inbox row inserted
  AFTER offset commit. Risk: message loss on consumer crash. Pattern:
  Idempotent Receiver requires the inbox write and side-effect to commit
  together; offset commits last.

### Important
- src/inventory/consumer.go:88 — unbounded retry. Pattern: Retry classifier
  must distinguish transient from permanent; permanent goes to DLQ
  immediately.

### System
- The inventory service has no listed cost owner in
  docs/services/order-fulfillment/README.md. With outbox + Debezium + Kafka,
  per-event cost lands somewhere — name it.

## Readiness tier impact
Currently: Service-ready. Production-ready blocked by the ack-before-commit
Critical and the System cost-owner gap.
```

### Step 5 — `/failure-mode` — what's the worst that can happen?

Before launch:

```text
/failure-mode against the order-fulfillment design from steps 1-4
```

Conversational output. The command walks the failure catalog against the design and names, for each likely failure:

- Root cause and the pattern that mitigates it.
- **System-level blast radius**: which tenants are affected, which compliance reports trip, which cost lines spike, which DR plan engages, which lifecycle phase the service is in.
- Required tests.

Plus the 8 review questions answered: first failure, worst duplicate, blocked partition, slow downstream, replay safety, DLQ ownership, retry budget, who pages.

This is where you find out that `partitionkey: tenant_id` will hot-spot once one tenant grows large (with concrete tenant-isolation impact), and that your replay strategy will re-send confirmation emails unless you flag a `replay: true` extension (with the cost and customer-trust implications spelled out).

### Step 6 — `/readiness` — what tier are we at?

```text
/readiness assess the order-fulfillment service for production launch
```

Conversational output. The command walks both technical evidence (tests, dashboards, alerts, runbooks, SLOs) and **system-concerns evidence** (ownership, tenancy, compliance class, cost owner, capacity envelope, DR posture, lifecycle plan). Missing evidence in any concern downgrades the tier.

Output:

- Current tier (Prototype / Service-ready / Production-ready / Enterprise-critical) with the unified five-level ladder.
- Concrete gaps: missing dashboard, no DR plan, no capacity test, no named cost owner, no compliance attestation, etc.
- The shortest path to the next tier.

If the readiness review surfaces system concerns the per-service README does not yet capture, the command suggests updating `docs/services/<slug>/README.md` so future reviews start with the new facts in place.

### Step 7 — `/ship` — go/no-go decision

The big one. This command spawns three subagents in parallel — review, failure-mode, readiness — then synthesizes and writes the decision to `docs/launches/<slug>-<YYYY-MM-DD>.md`.

```text
/ship the order-fulfillment service for production launch
```

The launch decision file follows this structure (Summary + System concerns + the decision body + Related artifacts):

```markdown
## Summary
- **Status**: NO-GO
- **Date**: 2026-05-06
- **Feature**: order-fulfillment
- **Tier achieved**: Service-ready (cannot claim Production-ready)
- **TL;DR**: Two Critical blockers — ack-before-commit and replay-sends-emails — must land before GO.

## System concerns
- **Owner team**: Orders Platform
- **Tenancy**: multi-tenant w/ tenant_id partitioning (hot-key risk noted)
- **Compliance**: PCI-adjacent (no card data in the pipeline)
- **Cost owner**: Orders Platform; per-event budget <TBD>
- **Capacity**: 1k orders/sec p99; growth +30% YoY
- **DR posture**: RPO 5 min, RTO 10 min, single-region active-passive
- **Lifecycle**: green-field; deprecation trigger <TBD>

## Ship Decision

### Blockers (must fix before ship)
- consumer.go:142 — ack-before-commit (Critical, from review subagent)
- replay sends duplicate confirmation emails (Critical, from failure-mode)

### Recommended fixes
- Add bounded retry with jitter (Important, from review)
- Capacity test under skewed tenant_id load (Important, from failure-mode)

### Acknowledged risks (none accepted yet)

### Rollback plan
- Trigger: DLQ depth > 100 in 5 min, or end-to-end latency p95 > 5s.
- Procedure: flip feature flag, halt CDC publisher, stop workflow workers, drain consumer, schema-rollback if needed.
- RTO: 10 minutes from page to flag flip.

## Related artifacts
- Design: `docs/designs/order-fulfillment-design.md`
- ADRs: `docs/adr/0001-temporal-saga.md`
- Contracts: `docs/contracts/orders.placed.v1.md`
- Runbooks: `docs/runbooks/dlq-orders-placed-v1.md`
- Service index: `docs/services/order-fulfillment/README.md`
```

`/ship` also updates the per-service README (bumping `Tier` and `Last reviewed`) and the system catalog. Confirmation in chat: `Ship decision: NO-GO. Written to docs/launches/order-fulfillment-2026-05-06.md. 2 blockers.`

The fan-out gives you three independent perspectives in one pass instead of running each command serially.

## 4. Command reference

| Command | Role in the system | Writes? | Example prompt |
| --- | --- | --- | --- |
| `/design` | Pick patterns and boundaries; write a service design with system concerns | yes | `/design Add a notifications service that consumes orders.placed.v1 and orders.cancelled.v1. Owner: Comms team.` |
| `/contract` | Define the wire contract: schemas, AsyncAPI, owner, compatibility, retention | yes (3 files) | `/contract Design payments.authorized.v1. Owner: Payments. Per-account ordering.` |
| `/architecture` | Record decisions: ADR for one decision, RFC for an option set, Implementation Plan for execution | yes | `/architecture ADR for using a workflow engine vs choreography for the refund flow.` |
| `/runbook` | Operational artifact for an incident type tied to a service or channel | yes | `/runbook for DLQ triage on orders.placed.v1.dlq.` |
| `/review` | Architectural review of a diff: patterns, contracts, anti-patterns, system blast radius | no (chat) | `/review the changes in src/payments/.` |
| `/failure-mode` | "What's the worst that can happen?" Per-failure blast radius across tenants, compliance, cost, DR | no (chat) | `/failure-mode for the new high-volume telemetry pipeline.` |
| `/readiness` | Map a service or change to a readiness tier; walk technical and system-concerns evidence | no (chat) | `/readiness for the inventory service before customer rollout.` |
| `/ship` | Fan-out: parallel review + failure-mode + readiness, synthesize go/no-go with rollback | yes | `/ship the payments service for the v2.0 release.` |

Every artifact-writing command (`/design`, `/contract`, `/architecture`, `/runbook`, `/ship`) also updates `docs/services/<slug>/README.md` and `docs/system/catalog.md` so the system stays navigable.

The Claude Code plugin namespaces these as `/distributed-systems-patterns:design`, `:review`, etc. The bare `/design` works when the plugin is the only source for that command name; the namespaced form always works.

## 5. Tips

**Scoping the input.** Most commands default to "the current diff or recent commits". To scope explicitly:

```text
/review only the consumer code in src/inventory/
/review the last 3 commits
/review the staged changes
```

**Combining commands in one turn.** Smaller services fit in one turn:

```text
/design and /contract for a webhook ingestion platform that accepts Stripe
and GitHub events, dedupes by provider delivery id, and republishes as
internal CloudEvents.
```

The skill will produce both outputs in a single response, sharing pattern decisions across them.

**When the skill won't auto-trigger.** If your prompt avoids distributed-systems vocabulary (no Kafka / queue / event / async / saga / etc.), the skill stays dormant. Force activation:

```text
Use the distributed-systems-patterns skill to <prompt>.
```

Or invoke a command directly — commands always activate the skill.

**Language-agnostic by default.** The skill produces architectural artifacts (decisions, contracts, runbooks) in any repo regardless of language. Patterns, anti-patterns, reliability questions, and system concerns are language-neutral. When you do ask for code at a pattern boundary, the skill uses the repo's language if one is detectable; if not, it stays at language-agnostic pseudocode rather than picking one.

For non-Go ecosystems, `reference/non-go-pointers.md` lists *options* (Spring Kafka / Spring Cloud Stream for Java, KafkaJS / NestJS for TypeScript, aiokafka / confluent-kafka-python for Python) without recommending a specific one — that's a team choice.

**Reading the references directly.** Every command names which reference file it loads. You can read those files directly to understand the source material:

```bash
cat ~/.agents/skills/distributed-systems-patterns/reference/decision-tree.md
cat ~/.agents/skills/distributed-systems-patterns/reference/checklist.md
```

**When the agent claims production-ready.** The skill is configured to NOT call code production-ready while reliability checklist items OR system-concerns evidence (owner, tenancy, cost, compliance, capacity, DR, lifecycle) is open. It downgrades to Service-ready or Prototype and lists the gaps. If you see "production-ready" in a response, verify both the technical checklist and the system-concerns block were actually answered.

## What's next

- Read `SKILL.md` for the canonical contract (the 8-question checklist, anti-pattern list, mandatory process).
- Read `reference/catalog.md` for the full pattern catalog.
- Read `reference/scenario-playbooks.md` for more end-to-end architectures (webhook platform, multi-tenant event bus, audit lake, payment workflow, broker migration, DLQ replay).
- For LLM-specific workflows, see `reference/llm-workflow-patterns.md`.
- For cost guardrails, see `reference/cost-and-finops.md`.
