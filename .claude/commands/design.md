---
description: Design an integration or event flow — patterns, modern tools, reliability checklist, written to a design doc
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/decision-tree.md` for problem-to-pattern lookup. Only load `reference/catalog.md` or `reference/modern-integration-field-guide.md` if the decision-tree branch points at a pattern you cannot name from memory or the user explicitly asks about modern realizations.

The user has a new integration or event-flow problem. Produce a written design document, not just a chat response. **Default to a tight design (target 100-150 lines).** A bloated design doc is a worse decision artifact than a tight one — readers skim and the cost of generating extra prose hurts iteration speed. If the user says "deep design", "full", or "thorough", expand each section; otherwise stay tight.

1. Classify the integration style: File Transfer, Shared Database, Remote Procedure Invocation, or Messaging. State why messaging/distribution is required instead of a simpler local design.
2. Walk `reference/decision-tree.md` to the matching problem branch and name the patterns from `reference/catalog.md` - integration patterns plus distributed-systems patterns when scale, resilience, or boundaries are in play.
3. Run the 8-question reliability checklist from SKILL.md: delivery guarantee, idempotency strategy, bad-message strategy, retry policy, ordering requirement, schema evolution, observability, and failure boundary. No "later" answers.
4. If services, scale, multi-region, or enterprise operations are in scope, also answer the 6-question distributed-systems checklist: ownership, consistency, scaling axis, failure mode, backpressure, operations.
5. Cite the modern realization for each pattern: CloudEvents 1.0, AsyncAPI 3.x, OpenTelemetry, Schema Registry, Debezium/Kafka/SQS/SNS/EventBridge/Pub/Sub/Temporal/Step Functions, KEDA, Envoy/Istio.
6. Flag any anti-pattern visible in the proposed shape: dual-write, ack-before-commit, unbounded retry, retry storm, distributed monolith, shared OLTP across services, distributed 2PC.
7. End with the readiness tier the design currently qualifies for and the gaps to reach Production-ready.

## Output

8. Before writing, run a Glob for `docs/features/<slug>/**` to enumerate existing peer artifacts (ADRs, contracts, schemas, asyncapi, runbooks, launches). Populate the **Related artifacts** section with concrete relative paths to existing peers; for peers that don't exist yet, list the conventional path with a `(not yet written)` annotation.

9. **Update the per-feature index and system catalog.** After writing the main artifact, also create or update:
   - `docs/features/<slug>/README.md` - the per-feature entry point. Append/update the relevant Artifacts subsection (Design / ADRs / Contracts / Runbooks / Launches) with a link to the new artifact. If the file does not exist, create it from the template in SKILL.md item 16.
   - `docs/system/catalog.md` - the system-level feature registry. Append/update the row for `<slug>`. If the file does not exist, create it from the template in SKILL.md item 17.
   These updates are part of the same command turn; do not leave them for a follow-up.

**Write the design to `docs/features/<feature-slug>/design.md`** in the current repo. Pick a slug from the user's prompt (e.g. `order-fulfillment`, `webhook-ingestion`). If `docs/features/<slug>/` does not exist, create it. If a file with the same name exists, ask before overwriting.

Use this structure:

```markdown
# <Feature> Design

## Summary
- **Status**: Draft | Proposed | Accepted
- **Date**: <YYYY-MM-DD>
- **TL;DR**: 1-2 sentence statement of what this design proposes and why.

## System concerns
- **Owner team**: <team / Slack / on-call escalation>
- **Tenancy**: <single-tenant | multi-tenant w/ specified isolation>
- **Compliance**: <none | PII | GDPR | SOC2 | PCI | data residency>
- **Cost owner**: <team / cost center / per-event budget>
- **Capacity**: <expected p50/p99 volume; growth assumption>
- **DR posture**: <RPO | RTO | region strategy>
- **Lifecycle**: <creation date; deprecation trigger; replacement plan>

## Integration style
[1-3 lines: which style and why messaging vs RPC vs shared DB vs file]

## Patterns
[Bullet list of named patterns from the catalog. One line per pattern, optionally one short clause of justification. No long paragraphs.]

## Reliability checklist (8 answers)
[One line per question: Delivery / Idempotency / Bad-message / Retry / Ordering / Schema / Observability / Failure-boundary. Answer in <=15 words each.]

## Distributed-systems checklist (6 answers, when applicable)
[One line per question: Boundary / Consistency / Scaling axis / Failure mode / Backpressure / Operations. Skip the section entirely if scale/resilience/multi-region is out of scope.]

## Modern realization
[Bullet list mapping each pattern to a tool *category* (e.g. "a CDC tool", "a Kafka-compatible broker"). Name specific packages only when the user has already picked one.]

## Anti-patterns to avoid
[Just the names from SKILL.md plus a 1-clause why-this-design-might-trip-it. No long paragraphs.]

## Boundary contracts (conceptual, not code)
[Bullet list per channel: name, event type, ordering key, idempotency key, retention, DLQ owner, compatibility mode. <=10 lines total. Schema details belong in /contract.]

## File and component plan
[Bullet list of <=15 source/migration/IaC paths the implementation will touch. One line per file. No code.]

## Open questions
[Bullet list of <=8 unresolved decisions with owner and target date. Use `<YYYY-MM-DD>` if no date.]

## Readiness tier and gaps
[Tier name + 3-5 bullet gaps to the next tier. Keep tight.]

## Related artifacts
[Paths are relative to `docs/features/<slug>/design.md`.]
- Architecture decisions: `adrs/` (feature-scoped ADRs that record specific choices made here)
- Contracts: `contracts/<channel>.md`, `schemas/<channel>.<ext>`, `asyncapi/<channel>.yaml`
- Runbooks: `runbooks/` (DLQ triage, replay, failover for the channels listed above)
- Launch decisions: `launches/<YYYY-MM-DD>.md`
- System catalog: `../../system/catalog.md`
```

**Strict rule: a design doc is a decision artifact, not a code artifact.** Do NOT include Go, SQL, JSON, YAML, or any implementation code blocks in this file. Specifically:

- "Boundary contracts" describes channel names, event types, ordering keys, idempotency keys, retention, DLQ owner, schema compatibility mode — at the *conceptual* level. The actual schemas and AsyncAPI specs are produced by `/contract` and live under `docs/features/<slug>/schemas/` and `docs/features/<slug>/asyncapi/`. Reference them by path, do not inline them.
- "File and component plan" is a bulleted file inventory: which source files / migrations / IaC the implementation will touch (e.g. `internal/orders/place.go`, `migrations/NNNN_add_outbox.sql`, `deploy/k8s/orders-consumer.yaml`). One line per file. No code.
- "Open questions" lists decisions still needed, with owners and target dates. Use `<YYYY-MM-DD>` placeholders if no date is set yet.

If the user wants implementation code, that is a follow-up step (regular prompt or `/architecture` for an Implementation Plan doc). If they want the actual schema and AsyncAPI files, route to `/contract`. If they want a runbook, route to `/runbook`.

Then emit a one-line confirmation in chat: `Design written to docs/features/<slug>/design.md`. Do not paste the full design back into chat unless the user asks.

If the user explicitly says "show in chat only" or "don't write a file", skip the file write and respond conversationally.
