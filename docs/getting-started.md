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

**Cold-start prompts give you guidance in chat.** The skill auto-activates on distributed-systems vocabulary and walks the patterns + reliability checklist + Go example, but does not save anything to disk unless you ask. Use cold-start when you're exploring or want to think out loud.

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

### Architectural-first by design

This skill produces decisions and contracts; code lives in source files. `/design` writes a decision doc with no inline code — patterns, channel and ordering choices, owners, alternatives, file inventory, and readiness tier. `/contract` writes schema files and AsyncAPI under `schemas/` and `asyncapi/`. `/architecture` writes ADRs and RFCs with trade-offs and rollout. `/review` evaluates a change architecturally — which patterns are touched, which contracts are affected, which checklist items are open — rather than line-by-line. `/runbook`, `/failure-mode`, `/readiness`, and `/ship` produce operational artifacts and decisions, not handlers.

If you want code, ask for it explicitly: "Show me a Go boundary snippet for the idempotent receiver." The skill will produce a minimal, library-agnostic sample at the pattern boundary — not a full production handler — and use the repo language when one is clear.

## 3. Walkthrough: shipping order fulfillment

A complete journey — pick patterns, define contracts, implement, review, ship. Each step uses one slash command.

### Step 1 — `/design` — pick the patterns

Type:

```text
/design Build an order-fulfillment system. Orders API writes to Postgres.
Downstream services: payments, inventory, shipping, notifications. Need a
saga that survives partial failures and supports compensation.
```

The command loads `reference/decision-tree.md` and `reference/catalog.md`, classifies the integration style, and produces:

- Pattern map: `Event Message + Transactional Outbox + Datatype Channel + Process Manager (Saga) + Idempotent Receiver + Dead Letter Channel + Compensation`.
- Modern realization: Postgres outbox + Debezium → Kafka, Temporal for the saga, CloudEvents envelopes, AsyncAPI 3.1 contracts.
- 8-question reliability checklist answered.
- A pattern-mapping table you can paste into a design doc.

### Step 2 — `/contract` — define `orders.placed.v1`

Type:

```text
/contract Design the orders.placed.v1 contract. Owner: Orders Platform team.
Producers: orders-service. Consumers: payments-service, inventory-service,
notifications-service. Required fields: order_id, customer_id, total_cents,
items[]. Need per-order ordering.
```

The command loads `reference/message-contract-template.md` and `reference/schema-migration.md` and produces:

- A CloudEvents 1.0.2 JSON envelope filled with your fields plus the standard extensions (`partitionkey: order_id`, `correlationid`, `causationid`, `traceparent`).
- An AsyncAPI 3.1 channel/operation/message/schema block for `orders.placed.v1`.
- Compatibility mode: BACKWARD (Confluent default; consumers can read new producer messages).
- A versioning policy stating when to spin up `orders.placed.v2` (renames, removed fields, semantic changes).
- A CI gate snippet for schema-compatibility checks.

### Step 3 — Implement

Ask normally:

```text
Implement the producer side of orders.placed.v1 in Go using the
Transactional Outbox pattern. Show the Postgres outbox schema, the
PlaceOrder function that writes the domain row + outbox row in one
transaction, and a Debezium connector config.
```

The skill produces production-shaped Go (matches `reference/go-examples.md`):

- Outbox SQL schema with the unpublished index.
- `PlaceOrder(ctx, tx, order)` writing both rows atomically, with `// Pattern: Transactional Outbox` annotations and CloudEvents envelope construction.
- OpenTelemetry trace-context injection on every hop.
- Notes on what NOT to do (publish directly after `tx.Commit()`).

### Step 4 — `/review` — production-readiness review

After your team writes the consumer, run:

```text
/review the inventory consumer in src/inventory/consumer.go and src/inventory/inbox.go
```

The command loads `reference/checklist.md` and `reference/failure-modes.md` and:

- Walks the 8-question reliability checklist + the distributed-systems checklist over the diff.
- Flags anti-patterns by file:line. Common hits in real reviews: missing `Idempotent Receiver`, ack-before-commit (offset committed before DB write), unbounded retry, no DLQ owner, payload switch on event type instead of `Datatype Channel`.
- Categorizes findings as Critical / Important / Suggestion.
- Recommends a readiness-tier downgrade if checklist items are unanswered.

Output shape:

```markdown
## Findings

### Critical
- src/inventory/consumer.go:142 — offset committed before inbox row inserted
  (ack-before-commit). Risk: message loss on consumer crash. Fix: commit
  offset only after `tx.Commit()` returns nil.

### Important
- src/inventory/consumer.go:88 — no max-retry cap; transient errors will
  loop forever. Fix: bounded exponential backoff with jitter, max 5 attempts,
  classified transient vs permanent.

### Suggestion
- src/inventory/inbox.go:23 — inbox retention not configured. Recommend 30 days
  to cover broker retention + replay window.

## Readiness tier
Currently: Service-ready (basic). Production-ready blocked by ack-before-commit
fix and DLQ owner declaration.
```

### Step 5 — `/failure-mode` — what's the worst that can happen?

Before launch:

```text
/failure-mode against the order-fulfillment design from steps 1-4
```

The command loads `reference/failure-modes.md` and walks the catalog against your design. Output:

- Top 5-7 failures most likely to bite first (duplicate delivery, hot partition by tenant, retry storm, replay side effect, schema drift, etc.).
- For each: root cause, impact, mitigation patterns, required tests.
- The 8 review questions answered: first failure, worst duplicate, blocked partition, slow downstream, replay safety, DLQ ownership, retry budget, who pages.

This is where you find out that your `partitionkey: tenant_id` choice will hot-spot once one tenant grows large, and that your replay strategy will re-send confirmation emails unless you flag a `replay: true` extension.

### Step 6 — `/readiness` — what tier are we at?

```text
/readiness assess the order-fulfillment service for production launch
```

The command loads `reference/production-guide.md`, `reference/maturity-model.md`, and `reference/checklist.md`, gathers evidence, and outputs:

- Current tier (from the unified five-level ladder: 0 Ad hoc, 1 Pattern-aware, 2 Reliable service, 3 Production-ready, 4 Enterprise-critical).
- Concrete gaps: missing dashboard, no DR plan, no capacity test, etc.
- The shortest path to the next tier.

### Step 7 — `/ship` — go/no-go decision

The big one. This command spawns three subagents in parallel — review, failure-mode, readiness — then synthesizes.

```text
/ship the order-fulfillment service for production launch
```

Output:

```markdown
## Ship Decision: NO-GO

### Tier
Service-ready (cannot claim Production-ready)

### Blockers
- consumer.go:142 — ack-before-commit (Critical, from review subagent)
- replay sends duplicate confirmation emails (Critical, from failure-mode)

### Recommended fixes
- Add bounded retry with jitter (Important, from review)
- Capacity test under skewed tenant_id load (Important, from failure-mode)

### Acknowledged risks (none accepted yet)

### Rollback plan
- Trigger: DLQ depth > 100 in 5 min, or end-to-end latency p95 > 5s.
- Procedure:
  1. Flip feature flag `orders.fulfillment.enabled = false`.
  2. Pause Debezium connector to halt outbox publishing.
  3. Stop Temporal workers; in-flight workflows pause.
  4. Drain inventory consumer (graceful shutdown).
  5. Schema-rollback if needed: revert producer to v1 only.
- RTO: 10 minutes from page to flag flip.
```

The fan-out gives you three independent perspectives in one pass instead of running each command serially.

## 4. Command reference

| Command | When to use | Example prompt |
| --- | --- | --- |
| `/design` | New integration / event flow / cross-service write | `/design Add a notifications service that consumes orders.placed.v1 and orders.cancelled.v1.` |
| `/review` | PR / diff review for production-readiness | `/review the changes in src/payments/` |
| `/architecture` | Need a decision-ready architecture doc, RFC, ADR, or implementation plan | `/architecture write an ADR for using Temporal vs Step Functions for the refund workflow` |
| `/contract` | Designing or reviewing an event/message contract | `/contract review payments.authorized.v1 — am I missing any CloudEvents extensions?` |
| `/runbook` | Need a runbook for an incident type | `/runbook for DLQ triage on orders.placed.v1.dlq` |
| `/failure-mode` | "What's the worst that could happen?" before launch | `/failure-mode for the new high-volume telemetry pipeline` |
| `/readiness` | Map a service / change to a readiness tier | `/readiness for the inventory service before customer rollout` |
| `/ship` | Production launch — full fan-out check | `/ship the payments service for the v2.0 release` |

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

**Non-Go codebases.** The skill defaults to Go. For Java / TypeScript / Python:

```text
/design [your prompt]. The repo is TypeScript with NestJS and KafkaJS.
```

The skill will load `reference/non-go-pointers.md` and produce idiomatic snippets for that stack while keeping the same patterns. Anti-patterns and reliability questions are language-agnostic.

**Reading the references directly.** Every command names which reference file it loads. You can read those files directly to understand the source material:

```bash
cat ~/.agents/skills/distributed-systems-patterns/reference/decision-tree.md
cat ~/.agents/skills/distributed-systems-patterns/reference/checklist.md
```

**When the agent claims production-ready.** The skill is configured to NOT call code production-ready while reliability checklist items are open — instead it downgrades to Service-ready or Prototype and lists the gaps. If you see "production-ready" in a response, verify the checklist was actually answered.

## What's next

- Read `SKILL.md` for the canonical contract (the 8-question checklist, anti-pattern list, mandatory process).
- Read `reference/catalog.md` for the full pattern catalog.
- Read `reference/scenario-playbooks.md` for more end-to-end architectures (webhook platform, multi-tenant event bus, audit lake, payment workflow, broker migration, DLQ replay).
- For LLM-specific workflows, see `reference/llm-workflow-patterns.md`.
- For cost guardrails, see `reference/cost-and-finops.md`.
