# Getting Started

A walkthrough of `distributed-systems-patterns` from install to shipping a real change. Uses the order-fulfillment scenario throughout so the commands chain naturally.

## 0. Is this skill for your problem?

The skill is for **distributed-systems work at scale**. It earns its weight when:

- Multiple services or teams must agree on contracts and ownership.
- A change introduces durable infrastructure (a broker, workflow engine, schema registry, mesh, cache fleet, shard, or new consistency model).
- The work needs decision artifacts that outlast the code (ADRs that future hires can read; runbooks that on-call engineers reach for at 2 a.m.).

> **Warning: do NOT use this skill for small projects.** Running the full 11-command pipeline on a side project, hackathon, class assignment, or scrappy MVP is overengineering theater. You will produce ten markdown files for code that doesn't exist yet. The skill assumes ≥2 services, real users, real operational cost, and real failure modes worth planning around. If those don't apply yet, a regular prompt without slash commands is faster, clearer, and produces less ceremony.

### Concrete don't-use cases

The skill is wrong for:

- **Side projects and hobby code.** Nobody but you will read the ADR.
- **Hackathons and prototypes.** Decisions you'll abandon in a week don't need durable artifacts.
- **Single-process apps.** A Flask/Express/FastAPI service with one Postgres database doesn't have the cross-team coordination problem the skill solves.
- **Frontend-only work.** UI components, React/Vue/Svelte apps, design-system code.
- **CRUD apps without async work.** REST endpoints over a single database, no queues, no background jobs.
- **Single-team startups under ~10 engineers.** Conway's Law says the architecture mirrors team structure; with one team there's no boundary to negotiate.
- **Single-function utilities.** A script, a lambda that does one thing, a CLI tool.
- **Beginner pattern questions.** "What is a queue?" "When do I use Redis vs Memcached?" — the skill assumes you already know.
- **ETL and batch pipelines that don't coordinate services.** Airflow DAGs that move data between two databases without crossing team boundaries.
- **Internal tools with single-digit users.** Admin dashboards, ops scripts, debug consoles.

**Threshold for invoking the full pipeline**: at least two services or two teams must coordinate; or the work introduces durable infrastructure (broker, workflow engine, schema registry, mesh, cache fleet, shard, new consistency model); or the request explicitly asks for an ADR / RFC / runbook / launch decision. If none of these apply, the skill is configured to decline the full pipeline and answer simply instead.

This walkthrough builds an order-fulfillment saga across four downstream services with multi-tenant partitioning, PCI compliance, and 1k orders/sec capacity. That is well above the threshold and demonstrates the skill working at full power. **If your real project is smaller than this scenario, run the walkthrough as-is to learn the workflow, then decide whether your actual work meets the threshold before adopting the skill on it.** Most projects don't.

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

If you want a persistent design doc instead of chat output, use `/design` with the same description — the command writes to `docs/features/<slug>/design.md` and emits a one-line confirmation. The cold-start prompt is for thinking out loud; commands are for deliverables.

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

### A connected system, not eleven standalone commands

Every artifact the skill writes lands inside one feature folder: `docs/features/<slug>/`. That folder holds the design, ADRs, contracts, schemas, AsyncAPI specs, runbooks, launches, and a README index — all as siblings. The per-feature README aggregates every artifact for one feature plus its ownership, tenancy, cost owner, compliance class, capacity, DR posture, and lifecycle. The system catalog at `docs/system/catalog.md` indexes every feature; platform-wide ADRs live next to it under `docs/system/adrs/`.

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

Two clicks from "the system" to "this channel's runbook".

### Shared knowledge across features

Beyond the per-feature folder, the skill maintains shared knowledge at `docs/system/` - things that apply to every feature, not just one. Examples:

- `docs/system/standards/observability.md` - "every service emits OpenTelemetry traces"
- `docs/system/standards/channel-naming.md` - "channels follow `<domain>.<event>.v<N>`"
- `docs/system/topology.md` - team ownership map across features
- `docs/system/runbooks/broker-outage.md` - what to do when the platform broker fails

The rule: reference, don't restate. When you write a feature design that observes the platform observability standard, link to `../../system/standards/observability.md` rather than restating the rule. Each per-feature README's `## Shared references` section lists the platform docs that apply to that feature.

To create a shared standard explicitly: `/standard <topic>` writes to `docs/system/standards/<topic>.md`. Use `/architecture` with platform-wide scope for cross-feature ADRs (broker choice, mesh policy). Use `/runbook` with platform scope for incidents affecting the whole platform (broker outage, region failover).

### Everything beyond code

Each artifact carries a `## System concerns` block covering owner team, tenancy, cost owner, compliance, capacity, DR posture, and lifecycle. Unknown fields stay as `<TBD>` so the question is forced. The skill is for the layer beyond code: org topology, tenant isolation, compliance lineage, capacity, cost ownership, DR, deprecation - alongside the patterns and contracts.

If you want code, ask for it explicitly: "Show me a Go boundary snippet for the idempotent receiver." The skill produces a minimal, library-agnostic sample at the pattern boundary, not a full production handler.

## 3. Walkthrough: shipping order fulfillment and locking in shared knowledge

A complete journey — pick patterns, define contracts, implement, review, ship, promote a recurring rule to a platform standard, then ship a second feature that inherits the standard. Each step uses one slash command.

### Reset before testing

If you've run this walkthrough before, clear the test artifacts so this is a clean run:

```bash
rm -rf docs schemas asyncapi
```

Run from the root of your test project (e.g. `cd ~/Desktop/testingskill`). The skill writes everything under `docs/`, `schemas/`, and `asyncapi/`; deleting those resets you to a known state. The skill itself is symlinked from `~/.agents/skills/distributed-systems-patterns/` and stays put.

### Time the run

Round-2 baselines on a typical machine (after the v0.3.0 trim):

| Step                     | Expected time                             |
| ------------------------ | ----------------------------------------- |
| Step 1 `/design`         | ~3 min                                    |
| Step 2 `/contract`       | ~2.5 min                                  |
| Step 3 `/implement`      | ~5-10 min (depends on file count)         |
| Step 4 `/test`           | ~3-5 min                                  |
| Step 5 `/review`         | ~1.5 min (chat only)                      |
| Step 6 `/failure-mode`   | ~1.5 min (chat only)                      |
| Step 7 `/readiness`      | ~1.5 min (chat only)                      |
| Step 8 `/ship`           | ~5 min (3 parallel subagents + synthesis) |
| Step 9 `/standard`       | ~1 min                                    |
| Step 10 second `/design` | ~2.5 min                                  |
| Step 11 inspect          | n/a (terminal verification)               |

Track yours and report any large deviations.

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

- Writes `docs/features/order-fulfillment/design.md` with `## Summary` (status, date, TL;DR), `## System concerns` (owner, tenancy, compliance, cost, capacity, DR, lifecycle — `<TBD>` for unknowns), pattern map, 8-question reliability checklist, distributed-systems checklist, modern-realization mapping (a CDC tool, a Kafka-compatible broker, a workflow engine — categories, not specific packages unless you ask), boundary contracts at the conceptual level, file/component plan, open questions, readiness tier.
- Creates or updates `docs/features/order-fulfillment/README.md` (per-feature index) with the design link and the system-concerns block.
- Creates or updates `docs/system/catalog.md` (top-level registry) with one row for the feature.
- Emits a one-line confirmation in chat: `Design written to docs/features/order-fulfillment/design.md` plus the updated index/catalog paths.

### Step 2 — `/contract` — define `orders.placed.v1`

Type:

```text
/contract Design the orders.placed.v1 contract. Owner: Orders Platform team.
Producers: orders-service. Consumers: payments-service, inventory-service,
notifications-service. Required fields: order_id, customer_id, total_cents,
items[]. Need per-order ordering.
```

The command writes three files, all under the producer feature's folder:

- `docs/features/order-fulfillment/schemas/orders.placed.v1.json` — payload schema (Avro/Protobuf/JSON Schema).
- `docs/features/order-fulfillment/asyncapi/orders.placed.v1.yaml` — AsyncAPI 3.1 channel + operation + message.
- `docs/features/order-fulfillment/contracts/orders.placed.v1.md` — human-readable contract with `## Summary` (status, date, channel, owner, TL;DR), `## System concerns` (compliance class, retention, cost), CloudEvents 1.0.2 envelope example, compatibility mode (BACKWARD by default), versioning policy (when v2 is required), DLQ owner, replay/redrive policy, and `## Related artifacts` linking back to the design (sibling path: `../design.md`).

It also updates `docs/features/order-fulfillment/README.md` (adds the channel to "Channels owned" and the contract to "Artifacts") and `docs/system/catalog.md` (refreshes the feature row).

Confirmation in chat: `Contract orders.placed.v1 written under docs/features/order-fulfillment/{schemas,asyncapi,contracts}/`

### Step 3 — `/implement` — generate code from the docs

The docs are done; now write the code. `/implement` reads the design, contracts, schemas, AsyncAPI specs, applicable platform standards, and per-feature README, then generates source files at the paths named in the design's File and component plan.

```text
/implement order-fulfillment
```

The command:

- Refuses to run if the design or contracts are missing (tells you which to run first).
- Detects the repo language from `go.mod`, `package.json`, `pyproject.toml`, etc. Asks if unclear; defaults to language-agnostic pseudocode if no answer.
- Reads the design's Patterns and Boundary contracts sections to know which patterns to enforce (Outbox, Idempotent Receiver, Process Manager, etc.).
- Reads applicable standards under `docs/system/standards/*.md` so the implementation satisfies them.
- Writes one source file at a time, each with a header comment naming the source design and inline `// Pattern: ...` annotations at the boundaries.
- Refuses to invent patterns not in the design — if you ask for a behavior not specified, it tells you to update the design first.

Confirmation per file: `Wrote internal/orders/place.go. Patterns: Transactional Outbox. Standards: observability.` Final summary lists files + patterns + standards + recommended next step (`/test`).

The implementation is grounded in the canonical decisions, so the code matches the docs without drift.

### Step 4 — `/test` — generate tests grounded in contracts

Now write tests that verify the implementation against the contracts and the patterns named in the design.

```text
/test order-fulfillment
```

The command:

- Refuses if the design, contracts, or implementation files are missing.
- Reads the design's Patterns section and applies the test-by-pattern rules from `reference/testing-strategy.md`:
  - Outbox -> commit-or-rollback test, duplicate/out-of-order publisher test.
  - Idempotent Receiver -> same message twice produces one side effect.
  - Dead Letter Channel -> poison message reaches DLQ; source not lost.
  - Retry classifier -> transient retries, permanent goes to DLQ.
  - Process Manager -> happy path, timeout, compensation, replay determinism.
- Parses the schema files to drive contract tests (the implementation must produce/consume messages matching the schema).
- Reads applicable standards and tests their Requirements (e.g. observability standard says "every service emits OpenTelemetry traces" -> test asserts trace context propagation).
- Writes test files using the repo's conventional layout (`*_test.go` for Go, `__tests__/` for TypeScript, `tests/` for Python).

Confirmation per file: `Wrote internal/orders/place_test.go. Tests: 6. Patterns covered: Transactional Outbox.` Final summary plus a CI command suggestion: `Run \`go test ./...\` to execute. Add to CI per reference/testing-strategy.md.`

### Step 5 — `/review` — architectural review

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

Findings categorize as **Critical** (launch-blocking anti-pattern or contract break), **Important** (reliability regression or contract weakening), **Suggestion** (architecture tightening), or **System** (touches ownership, tenancy, compliance, cost, capacity, DR, or lifecycle). Conversational output — not a file. If material new System facts emerge, the command suggests updating `docs/features/<slug>/README.md`.

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
  docs/features/order-fulfillment/README.md. With outbox + Debezium + Kafka,
  per-event cost lands somewhere — name it.

## Readiness tier impact

Currently: Service-ready. Production-ready blocked by the ack-before-commit
Critical and the System cost-owner gap.
```

### Step 6 — `/failure-mode` — what's the worst that can happen?

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

### Step 7 — `/readiness` — what tier are we at?

```text
/readiness assess the order-fulfillment service for production launch
```

Conversational output. The command walks both technical evidence (tests, dashboards, alerts, runbooks, SLOs) and **system-concerns evidence** (ownership, tenancy, compliance class, cost owner, capacity envelope, DR posture, lifecycle plan). Missing evidence in any concern downgrades the tier.

Output:

- Current tier (Prototype / Service-ready / Production-ready / Enterprise-critical) with the unified five-level ladder.
- Concrete gaps: missing dashboard, no DR plan, no capacity test, no named cost owner, no compliance attestation, etc.
- The shortest path to the next tier.

If the readiness review surfaces system concerns the per-feature README does not yet capture, the command suggests updating `docs/features/<slug>/README.md` so future reviews start with the new facts in place.

### Step 8 — `/ship` — go/no-go decision

The big one. This command spawns three subagents in parallel — review, failure-mode, readiness — then synthesizes and writes the decision to `docs/features/<slug>/launches/<YYYY-MM-DD>.md`.

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

- Design: `../design.md`
- ADRs: `../adrs/0001-temporal-saga.md`
- Contracts: `../contracts/orders.placed.v1.md`
- Runbooks: `../runbooks/dlq-orders-placed-v1.md`
- Feature index: `../README.md`

## Shared references

- Observability standard: `../../system/standards/observability.md`
- Channel-naming standard: `../../system/standards/channel-naming.md`
- Broker outage runbook: `../../system/runbooks/broker-outage.md`
```

`/ship` also updates the per-feature README (bumping `Tier` and `Last reviewed`) and the system catalog. Confirmation in chat: `Ship decision: NO-GO. Written to docs/features/order-fulfillment/launches/2026-05-06.md. 2 blockers.`

The fan-out gives you three independent perspectives in one pass instead of running each command serially.

### Step 9 — `/standard` — lock in a platform convention

Once a pattern shows up in three feature designs (e.g. all three say "we emit OpenTelemetry traces"), promote it to a shared standard:

```text
/standard observability — every service must emit OpenTelemetry traces with
traceparent propagated; metrics for lag/age/DLQ depth; structured logs with
correlation_id. Owner: Platform Engineering.
```

The command writes `docs/system/standards/observability.md` (Status, Date, Owner, Rule, Requirements, Enforcement, Exceptions) and adds a row to `docs/system/catalog.md` Cross-cutting concerns. Every feature README's `## Shared references` section can now link to this standard instead of restating it.

Confirmation: `Standard written to docs/system/standards/observability.md`.

### Step 10 — second `/design` — watch shared knowledge get inherited

Now build a second feature and watch it reference the standard from Step 8 instead of restating it. This is the payoff demonstration of "reference, don't restate."

```text
/design Build a webhook-ingestion platform. Accept Stripe and GitHub
webhook deliveries, verify signatures, dedupe by provider delivery id,
and republish as internal CloudEvents on `webhooks.received.v1`.
Owner: Platform Engineering. Multi-tenant via tenant_id in URL path.
PII may appear in payload bodies. Capacity 5k webhooks/sec p99.
```

Watch the output:

- Writes `docs/features/webhook-ingestion/design.md`. Its `## Shared references` section should link to `../../system/standards/observability.md` from Step 8 — the agent globbed `docs/system/standards/`, found the observability standard applies, and referenced it instead of restating "we emit OpenTelemetry traces."
- Creates `docs/features/webhook-ingestion/README.md` with its own `## Shared references` section pointing at the same standard.
- Adds a row for `webhook-ingestion` to `docs/system/catalog.md`. Catalog now has two features.

If the agent skips the `## Shared references` section or restates the observability rule inline, the skill regressed — tell me which step.

### Step 11 — inspect the connected system

After all 10 steps, the test project should look like this:

```
docs/
├── system/
│   ├── catalog.md                      # both features listed
│   └── standards/
│       └── observability.md            # from Step 8
└── features/
    ├── order-fulfillment/
    │   ├── README.md                   # links to design, contracts, ADRs, runbooks, launches
    │   ├── design.md
    │   ├── adrs/0001-saga-orchestrator.md
    │   ├── contracts/orders.placed.v1.md
    │   ├── schemas/orders.placed.v1.json
    │   ├── asyncapi/orders.placed.v1.yaml
    │   ├── runbooks/dlq-triage.md      # if you ran /runbook
    │   └── launches/2026-05-06.md      # from Step 7
    └── webhook-ingestion/
        ├── README.md                   # references observability standard
        └── design.md                   # references observability standard
```

Verify the connected system from your terminal:

```bash
echo "=== System catalog (should list 2 features) ==="
cat docs/system/catalog.md

echo
echo "=== Order-fulfillment per-feature index ==="
cat docs/features/order-fulfillment/README.md

echo
echo "=== Webhook-ingestion design's Shared references (should link to observability) ==="
sed -n '/## Shared references/,/^## /p' docs/features/webhook-ingestion/design.md

echo
echo "=== All cross-links resolve (empty = good) ==="
find docs -name '*.md' | while read f; do
  grep -oE '\[[^]]+\]\([^)]+\.md\)' "$f" | grep -oE '\([^)]+\)' | tr -d '()' | while read link; do
    target="$(cd "$(dirname "$f")" && cd "$(dirname "$link")" 2>/dev/null && pwd)/$(basename "$link")"
    [ -f "$target" ] || echo "BROKEN: $f -> $link"
  done
done
```

The two-click navigation should work end to end: `docs/system/catalog.md` → click the order-fulfillment README link → click the orders.placed.v1 contract link → see schema + asyncapi as siblings. From the same catalog, click the webhook-ingestion README → see its `## Shared references` linking back to the platform observability standard.

That's the connected system: per-feature folders aggregate everything for one feature; the per-feature README serves as the entry point; shared knowledge in `docs/system/` is referenced (not restated) by every feature; the catalog at `docs/system/catalog.md` indexes the whole system.

## 4. Command reference

| Command         | Role in the system                                                                                | Writes?                                                                 | Example prompt                                                                                                   |
| --------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `/design`       | Pick patterns and boundaries; write a service design with system concerns                         | yes (under `docs/features/<slug>/`)                                     | `/design Add a notifications service that consumes orders.placed.v1 and orders.cancelled.v1. Owner: Comms team.` |
| `/contract`     | Define the wire contract: schemas, AsyncAPI, owner, compatibility, retention                      | yes (3 files under `docs/features/<slug>/`)                             | `/contract Design payments.authorized.v1. Owner: Payments. Per-account ordering.`                                |
| `/implement`    | Generate code from existing design + contracts + standards. Refuses to run without docs.          | yes (source files at paths in the design's File and component plan)     | `/implement order-fulfillment`                                                                                   |
| `/test`         | Generate tests grounded in contracts + design (idempotency, retry, DLQ, replay, contract compat)  | yes (test files alongside source)                                       | `/test order-fulfillment`                                                                                        |
| `/architecture` | Record decisions: ADR for one decision, RFC for an option set, Implementation Plan for execution  | yes (under `docs/features/<slug>/adrs/` or `docs/system/adrs/`)         | `/architecture ADR for using a workflow engine vs choreography for the refund flow.`                             |
| `/standard`     | Platform convention every feature follows                                                         | yes (under `docs/system/standards/<topic>.md`)                          | `/standard observability — every service emits OpenTelemetry traces.`                                            |
| `/runbook`      | Operational artifact for an incident type tied to a service, channel, or the platform             | yes (under `docs/features/<slug>/runbooks/` or `docs/system/runbooks/`) | `/runbook for DLQ triage on orders.placed.v1.dlq.`                                                               |
| `/review`       | Architectural review of a diff: patterns, contracts, anti-patterns, system blast radius           | no (chat)                                                               | `/review the changes in src/payments/.`                                                                          |
| `/failure-mode` | "What's the worst that can happen?" Per-failure blast radius across tenants, compliance, cost, DR | no (chat)                                                               | `/failure-mode for the new high-volume telemetry pipeline.`                                                      |
| `/readiness`    | Map a service or change to a readiness tier; walk technical and system-concerns evidence          | no (chat)                                                               | `/readiness for the inventory service before customer rollout.`                                                  |
| `/ship`         | Fan-out: parallel review + failure-mode + readiness, synthesize go/no-go with rollback            | yes (under `docs/features/<slug>/launches/`)                            | `/ship the payments service for the v2.0 release.`                                                               |

Every artifact-writing command (`/design`, `/contract`, `/implement`, `/test`, `/architecture`, `/standard`, `/runbook`, `/ship`) writes to predictable paths and most also update `docs/features/<slug>/README.md` and `docs/system/catalog.md` so the system stays navigable. `/implement` and `/test` write source/test files; the others write architectural artifacts.

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

For non-Go ecosystems, `reference/non-go-pointers.md` lists _options_ (Spring Kafka / Spring Cloud Stream for Java, KafkaJS / NestJS for TypeScript, aiokafka / confluent-kafka-python for Python) without recommending a specific one — that's a team choice.

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
