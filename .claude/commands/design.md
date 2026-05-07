---
description: Design an integration or event flow — patterns, modern tools, reliability checklist, written to a design doc
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/decision-tree.md` for problem-to-pattern lookup. Only load `reference/catalog.md` if the decision-tree branch points at a pattern you cannot name from memory.

The user has a new integration or event-flow problem. Produce a written design document, not just a chat response. **Default to a tight design (target 60-80 lines).** A bloated design doc is a worse decision artifact than a tight one — readers skim and the cost of generating extra prose hurts iteration speed. If the user says "deep design", "full", or "thorough", expand each section; otherwise stay tight.

1. Walk `reference/decision-tree.md` to the matching problem branch and name the patterns from `reference/catalog.md` — integration patterns plus distributed-systems patterns when scale, resilience, or boundaries are in play.
2. Run the 8-question reliability checklist from SKILL.md: delivery guarantee, idempotency strategy, bad-message strategy, retry policy, ordering requirement, schema evolution, observability, and failure boundary. No "later" answers.
3. Capture the system concerns: owner team, tenancy, compliance, cost owner, capacity, DR posture, lifecycle. Fold the integration-style choice (messaging vs RPC vs shared DB vs file) into the Summary TL;DR.
4. Flag any anti-pattern visible in the proposed shape: dual-write, ack-before-commit, unbounded retry, retry storm, distributed monolith, shared OLTP across services, distributed 2PC.
5. Sketch boundary contracts at the conceptual level only (channel name, ordering key, idempotency key, retention, DLQ owner, compatibility mode). Schema details belong in `/contract`.

## Output

6. Before writing, run a Glob for `docs/features/<slug>/**` to enumerate existing peer artifacts (ADRs, contracts, schemas, asyncapi, runbooks, launches). Populate the **Related artifacts** section with concrete relative paths to existing peers; for peers that don't exist yet, list the conventional path with a `(not yet written)` annotation.

7. **Update the per-feature index and system catalog.** After writing the main artifact, also create or update:
   - `docs/features/<slug>/README.md` — the per-feature entry point. Append/update the relevant Artifacts subsection (Design / ADRs / Contracts / Runbooks / Launches) with a link to the new artifact. If the file does not exist, create it from the template in SKILL.md item 16.
   - `docs/system/catalog.md` — the system-level feature registry. Append/update the row for `<slug>`. If the file does not exist, create it from the template in SKILL.md item 17.
   These updates are part of the same command turn; do not leave them for a follow-up.

**Write the design to `docs/features/<feature-slug>/design.md`** in the current repo. Pick a slug from the user's prompt (e.g. `order-fulfillment`, `webhook-ingestion`). If `docs/features/<slug>/` does not exist, create it. If a file with the same name exists, ask before overwriting.

Use this structure:

```markdown
# <Feature> Design

## Summary
- **Status**: Draft | Proposed | Accepted
- **Date**: <YYYY-MM-DD>
- **TL;DR**: 1-2 sentences. Include integration style (messaging vs RPC vs shared DB vs file) and why.

## System concerns
- **Owner team**: <team / Slack / on-call>
- **Tenancy**: <single | multi-tenant w/ isolation>
- **Compliance**: <none | PII | GDPR | SOC2 | PCI | data residency>
- **Cost owner**: <team>
- **Capacity**: <expected p99 volume; growth>
- **DR posture**: <RPO | RTO | region strategy>
- **Lifecycle**: <created; deprecation trigger>

## Patterns
[Bullet list. One line per pattern. <=10 patterns.]

## Reliability checklist (8 answers)
[One line per question: Delivery / Idempotency / Bad-message / Retry / Ordering / Schema / Observability / Failure-boundary. <=15 words each.]

## Boundary contracts (conceptual, not code)
[Bullet list per channel: name, ordering key, idempotency key, retention, DLQ owner, compatibility mode. <=10 lines.]

## Anti-patterns to avoid
[Bullet list. <=5 items. Name + 1-clause why-this-design-might-trip-it.]

## Open questions
[Bullet list with owner + target date. <=5 items. Use `<YYYY-MM-DD>` if no date.]

## Related artifacts
[Sibling/child paths to peer artifacts.]
- ADRs: `adrs/`
- Contracts: `contracts/<channel>.md`, `schemas/<channel>.<ext>`, `asyncapi/<channel>.yaml`
- Runbooks: `runbooks/`
- Launches: `launches/<YYYY-MM-DD>.md`
- System catalog: `../../system/catalog.md`
```

**Strict rule: a design doc is a decision artifact, not a code artifact.** Do NOT include Go, SQL, JSON, YAML, or any implementation code blocks in this file. "Boundary contracts" stays at the conceptual level — the actual schemas and AsyncAPI specs are produced by `/contract` and live under `docs/features/<slug>/schemas/` and `docs/features/<slug>/asyncapi/`. Reference them by path, do not inline them.

If the user wants implementation guidance, route to `/architecture` for an Implementation Plan doc. If they want the actual schema and AsyncAPI files, route to `/contract`. If they want a runbook, route to `/runbook`.

**Before returning, run the auto self-check** (SKILL.md item 18): scan for anti-patterns in the design, refuse all-`<TBD>` system concerns, verify cross-link integrity in `## Related artifacts`. Critical findings are fixed inline; Important findings are reported in chat as a follow-up note ("Self-check flagged: <issue>. The design is written; recommend revising via `revise: <change>`.").

Then emit a one-line confirmation in chat: `Design written to docs/features/<slug>/design.md`. Do not paste the full design back into chat unless the user asks.

If the user explicitly says "show in chat only" or "don't write a file", skip the file write and respond conversationally.
