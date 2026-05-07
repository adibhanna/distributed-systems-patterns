# Getting Started

A walkthrough of `distributed-systems-patterns` from install to shipping a real change. Uses the order-fulfillment scenario throughout so the commands chain naturally.

## 0. Is this skill for your problem?

The skill is for **distributed-systems work at scale**. It earns its weight when:

- Multiple services or teams must agree on contracts and ownership.
- A change introduces durable infrastructure (a broker, workflow engine, schema registry, mesh, cache fleet, shard, or new consistency model).
- The work needs decision artifacts that outlast the code (ADRs that future hires can read; runbooks that on-call engineers reach for at 2 a.m.).

> **Warning: do NOT use this skill for small projects.** Running the full set of commands on a side project, hackathon, class assignment, or scrappy MVP is overengineering theater. You will produce ten markdown files for code that doesn't exist yet. The skill assumes ≥2 services, real users, real operational cost, and real failure modes worth planning around. If those don't apply yet, a regular prompt without slash commands is faster, clearer, and produces less ceremony.

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

**Threshold for invoking the skill**: at least two services or two teams must coordinate; or the work introduces durable infrastructure (broker, workflow engine, schema registry, mesh, cache fleet, shard, new consistency model); or the request explicitly asks for an ADR / RFC / runbook / launch decision. If none of these apply, the skill is configured to decline and answer simply instead.

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

**Commands write files** for structured deliverables (design docs, ADRs, contract schemas, runbooks, launch decisions). Use `/design`, `/architecture`, `/contract`, `/runbook`, `/prelaunch` whenever you want a persistent artifact in the repo.

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
Verification: 8-question checklist + tests (idempotency, DLQ, replay)
```

If the agent goes straight to a recommendation without naming patterns or running the checklist, the skill didn't activate. Force it:

```text
Use the distributed-systems-patterns skill: design an order-placed event flow.
```

All 6 commands write to predictable paths under `docs/features/<slug>/` and `docs/system/`. The per-feature README aggregates artifacts; the system catalog indexes features. There's no orchestrator - run commands as needed.

### Shared knowledge across features

Beyond the per-feature folder, the skill maintains shared knowledge at `docs/system/` - things that apply to every feature, not just one. Examples:

- `docs/system/topology.md` - team ownership map across features
- `docs/system/runbooks/broker-outage.md` - what to do when the platform broker fails
- `docs/system/adrs/0001-broker-choice.md` - platform-wide broker decision

The rule: reference, don't restate. When you write a feature design that observes a platform convention, link to the shared doc rather than restating the rule. Each per-feature README's `## Shared references` section lists the platform docs that apply to that feature.

To create cross-feature artifacts: use `/architecture` with platform scope for cross-feature ADRs (broker choice, mesh policy). Use `/runbook` with platform scope for incidents affecting the whole platform (broker outage, region failover). Other shared docs (glossary, topology, capacity, compliance, dr) are user-created markdown files.

### Everything beyond code

Each artifact carries a `## System concerns` block covering owner team, tenancy, cost owner, compliance, capacity, DR posture, and lifecycle. Unknown fields stay as `<TBD>` so the question is forced. The skill is for the layer beyond code: org topology, tenant isolation, compliance lineage, capacity, cost ownership, DR, deprecation - alongside the patterns and contracts.

The skill does NOT generate implementation code or tests. Your team's existing dev environment, test frameworks, and CI handle those better.

## 3. Walkthrough: shipping order fulfillment

A complete journey using the 6 commands. Each command is invoked individually - there's no orchestrator. Reset the test project before starting:

```bash
rm -rf docs schemas asyncapi
```

Run from the root of your test project (e.g. `cd ~/Desktop/testingskill`). The skill writes everything under `docs/`; deleting that resets you to a known state. The skill itself is symlinked from `~/.agents/skills/distributed-systems-patterns/` and stays put.

### Time the run

Round-2 baselines on a typical machine (after the v0.6.0 trim):

| Step                  | Expected time                |
| --------------------- | ---------------------------- |
| Step 1 `/design`      | ~3 min                       |
| Step 2 `/contract`    | ~2.5 min per channel         |
| Step 3 implementation | done by your team, not timed |
| Step 4 `/review`      | ~2 min (chat only)           |
| Step 5 `/runbook`     | ~2 min per incident type     |
| Step 6 `/prelaunch`   | ~3 min                       |

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

Output: `docs/features/order-fulfillment/design.md` (60-80 lines), per-feature README at `docs/features/order-fulfillment/README.md`, and a row added to `docs/system/catalog.md`. Read the design and approve or refine before continuing. The design contains `## Summary` (status, date, TL;DR), `## System concerns` (owner, tenancy, compliance, cost, capacity, DR, lifecycle — `<TBD>` for unknowns), pattern map, 8-question reliability checklist, boundary contracts at the conceptual level, open questions, and readiness tier.

### Step 2 — `/contract` — define each channel

Repeat this command for each channel listed in the design's Boundary contracts section. For order fulfillment, that means `orders.placed.v1`, `payments.authorized.v1`, `inventory.reserved.v1`, etc.

```text
/contract Design the orders.placed.v1 contract. Owner: Orders Platform team.
Producers: orders-service. Consumers: payments-service, inventory-service,
notifications-service. Required fields: order_id, customer_id, total_cents,
items[]. Need per-order ordering.
```

Output per channel (~40 lines per contract doc):

- `docs/features/order-fulfillment/schemas/<channel>.<ext>` — payload schema (Avro/Protobuf/JSON Schema).
- `docs/features/order-fulfillment/asyncapi/<channel>.yaml` — AsyncAPI 3.1 channel + operation + message.
- `docs/features/order-fulfillment/contracts/<channel>.md` — human-readable contract with status, owner, compatibility mode, DLQ owner, replay/redrive policy, and `## Related artifacts` linking back to the design.

The per-feature README and system catalog both pick up the new channels automatically.

### Step 3 — Implementation lives outside the skill

Your team writes the implementation in their normal dev environment. The design's Boundary contracts and the contract files are the inputs. The skill does NOT generate code, run tests, or scaffold the project.

If you need an architectural decision recorded mid-implementation (e.g. "saga orchestrator vs choreography for THIS service"), run `/architecture` to write an ADR or RFC under `docs/features/<slug>/adrs/`.

### Step 4 — `/review` — architectural review of the diff

After your team writes the consumer, run:

```text
/review the inventory consumer in src/inventory/consumer.go and src/inventory/inbox.go
```

This is **architectural review**, not line-by-line code review. The command identifies which patterns the change touches, which contracts it affects, which anti-patterns it introduces, the top failure modes with blast radius, and the readiness tier verdict with gaps.

Findings categorize as **Critical** (launch-blocking anti-pattern or contract break), **Important** (reliability regression or contract weakening), **Suggestion** (architecture tightening), or **System** (touches ownership, tenancy, compliance, cost, capacity, DR, or lifecycle). Conversational output — no file written. The command walks the 8-question reliability checklist, the distributed-systems checklist, and the anti-pattern catalog in one pass.

### Step 5 — `/runbook` (optional, per incident type)

For each likely incident, write a runbook:

```text
/runbook for DLQ triage on orders.placed.v1.dlq. Owner: Orders Platform.
Page on depth > 100 in 5 min. Common causes: schema-validation failure,
downstream timeout. Replay: dry-run first.
```

Output: `docs/features/order-fulfillment/runbooks/dlq-triage.md`. Run again for replay, partition lag, schema rollback, etc. Use `/runbook` with platform scope for cross-feature incidents (broker outage, region failover) - those write to `docs/system/runbooks/`.

### Step 6 — `/prelaunch` — GO/NO-GO

The launch gate:

```text
/prelaunch the order-fulfillment service for production launch
```

Output: `docs/features/order-fulfillment/launches/<YYYY-MM-DD>.md` with the launch decision, blockers, recommended fixes, acknowledged risks, and rollback plan. The command runs `/review`'s logic and writes the result with status (GO / NO-GO / GO-WITH-RISKS), tier achieved, the unfixed Critical and Important findings as blockers and recommended fixes, and a rollback procedure with trigger and RTO.

It also updates the per-feature README (bumping `Tier` and `Last reviewed`) and the system catalog. Confirmation in chat: `Ship decision: NO-GO. Written to docs/features/order-fulfillment/launches/<date>.md. 2 blockers.`

## 4. Command reference

| Command         | Role in the system                                                                       | Writes?                                                                 |
| --------------- | ---------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `/design`       | Pick patterns and boundaries; write a service design with system concerns                | yes (under `docs/features/<slug>/`)                                     |
| `/contract`     | Define the wire contract: schemas, AsyncAPI, owner, compatibility, retention             | yes (3 files under `docs/features/<slug>/`)                             |
| `/architecture` | Record decisions: ADR for one decision, RFC for an option set, Implementation Plan       | yes (under `docs/features/<slug>/adrs/` or `docs/system/adrs/`)         |
| `/runbook`      | Operational artifact for an incident type tied to a service, channel, or the platform   | yes (under `docs/features/<slug>/runbooks/` or `docs/system/runbooks/`) |
| `/review`       | Architectural review of a diff: patterns, contracts, anti-patterns, failure modes, tier  | no (chat)                                                               |
| `/prelaunch`    | Launch decision file with blockers, fixes, risks, and a rollback plan                    | yes (under `docs/features/<slug>/launches/`)                            |

The Claude Code plugin namespaces these as `/distributed-systems-patterns:design`, `:review`, etc. The bare `/design` works when the plugin is the only source for that command name; the namespaced form always works.

All 6 commands write to predictable paths under `docs/features/<slug>/` and `docs/system/`. The per-feature README aggregates artifacts; the system catalog indexes features. There's no orchestrator - run commands as needed.

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

**Language-agnostic by default.** The skill produces architectural artifacts (decisions, contracts, runbooks) in any repo regardless of language. Patterns, anti-patterns, reliability questions, and system concerns are language-neutral. The skill recommends tool categories (a Kafka client, a CDC tool) before specific packages; specific package picks stay with your team.

For non-Go ecosystems, `reference/non-go-pointers.md` lists _options_ (Spring Kafka / Spring Cloud Stream for Java, KafkaJS / NestJS for TypeScript, aiokafka / confluent-kafka-python for Python) without recommending a specific one — that's a team choice.

**Reading the references directly.** Every command names which reference file it loads. You can read those files directly to understand the source material:

```bash
cat ~/.agents/skills/distributed-systems-patterns/reference/decision-tree.md
cat ~/.agents/skills/distributed-systems-patterns/reference/checklist.md
```

**When the agent claims production-ready.** The skill is configured to NOT call a change production-ready while reliability checklist items OR system-concerns evidence (owner, tenancy, cost, compliance, capacity, DR, lifecycle) is open. It downgrades to Service-ready or Prototype and lists the gaps. If you see "production-ready" in a response, verify both the technical checklist and the system-concerns block were actually answered.

## What's next

- Read `SKILL.md` for the canonical contract (the 8-question checklist, anti-pattern list, mandatory process).
- Read `reference/catalog.md` for the full pattern catalog.
- Read `reference/scenario-playbooks.md` for more end-to-end architectures (webhook platform, multi-tenant event bus, audit lake, payment workflow, broker migration, DLQ replay).
- For LLM-specific workflows, see `reference/llm-workflow-patterns.md`.
- For cost guardrails, see `reference/cost-and-finops.md`.
