---
description: Architectural review of the diff — patterns, contracts, anti-patterns, failure modes, readiness tier, system blast radius. Conversational; no file written.
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/checklist.md` for the production review gates, `reference/failure-modes.md` for failure-pattern matching, and `reference/maturity-model.md` for the readiness tier check.

Architectural review, not line-by-line code review. Findings are categorized by which pattern, contract, anti-pattern, or reliability question they touch. Use file:line references to ground findings, but the category is always architectural. This command absorbs the failure-mode walk and the readiness verdict — the user gets one comprehensive review.

1. Enumerate the diff or recent commits: producers, consumers, brokers, topics, queues, outbox tables, workflows, schemas, DLQs, retry/backoff config, partition keys, config and secret surfaces.
2. Identify patterns touched: Outbox, Process Manager, Idempotent Receiver, Circuit Breaker, Cache-Aside, Sharding, Saga, CDC, Replay, Backpressure, and any others the change exercises.
3. Identify contracts affected: new event channels, schema changes, compatibility breaks, DLQ ownership shifts, new producer or consumer boundaries.
4. Walk the 8-question reliability checklist with respect to the change — delivery guarantee, idempotency, bad-message strategy, retry policy, ordering, schema evolution, observability, failure boundary — and mark each question as Answered, Open, or Regressed.
5. Walk the distributed-systems checklist when the change touches scale, resilience, multi-region, or service boundaries: ownership, consistency, scaling axis, failure mode, backpressure, operations.
6. Identify anti-patterns introduced or removed: dual-write, ack-before-commit, unbounded retry, retry storm, distributed monolith, shared OLTP, distributed 2PC, oversized broker payloads, missing trace context, autoscaling on the wrong signal, distributed locks without fencing.
7. **Failure-mode walk.** Walk the failure catalog from `reference/failure-modes.md` against the design surface. Name the top 3-5 likely failures with: root cause, system-level blast radius (which tenants, which compliance class, which cost line), required mitigation pattern, required test.
8. Walk the **System concerns** angle alongside the technical review: who owns this change? Does it touch tenant boundaries, compliance class, cost ownership, capacity envelope, or DR posture? Findings that cross these boundaries are categorized as `System` severity (in addition to Critical/Important/Suggestion).
9. **Readiness verdict.** Final tier verdict (Prototype / Service-ready / Production-ready / Enterprise-critical) with concrete gaps to the next tier. Walk both technical evidence (tests, dashboards, runbooks) and system-concerns evidence (ownership, tenancy, cost, compliance, capacity, DR, lifecycle). Missing evidence in any concern downgrades the tier.

Categorize findings: **Critical** (introduces a launch-blocking anti-pattern or breaks a contract), **Important** (regresses a reliability answer or weakens a contract), **Suggestion** (architecture tightening that is not strictly required), **System** (changes ownership, tenancy, compliance, cost, capacity, DR, or lifecycle posture). Cite file:line for each finding to ground it.

## Output

This command produces conversational findings, not a file. Use `/architecture` if the user wants a permanent decision artifact, `/prelaunch` for a launch-decision document.

Structure the response as:

```markdown
## Findings
### Critical
[Bullets with file:line]
### Important
[Bullets with file:line]
### Suggestion
[Bullets with file:line]
### System
[Bullets with file:line]

## Reliability checklist
[8-question table: Answered / Open / Regressed]

## Distributed-systems checklist
[6-question table when applicable]

## Anti-patterns
[Bullets: which were checked; which fired; which are forward-looking risks]

## Failure-mode walk
[Top 3-5 failures with root cause, blast radius, mitigation, required test]

## Readiness verdict
Tier: <Prototype | Service-ready | Production-ready | Enterprise-critical>
Gaps to next tier:
- [Bullets — both technical and system-concerns evidence]
```

If review findings reveal owner, tenancy, cost, compliance, capacity, DR, or lifecycle facts that should be persisted, suggest updating `docs/features/<slug>/README.md` accordingly. Do not auto-write; the user owns the persistence decision for analytical findings.
