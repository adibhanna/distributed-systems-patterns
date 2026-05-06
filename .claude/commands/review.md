---
description: Architectural review of the diff — patterns touched, contracts affected, anti-patterns introduced, readiness-tier impact
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/checklist.md` for the production review gates, `reference/failure-modes.md` for failure-pattern matching, and `reference/maturity-model.md` for the readiness tier check.

Architectural review, not line-by-line code review. Findings are categorized by which pattern, contract, anti-pattern, or reliability question they touch. Use file:line references to ground findings, but the category is always architectural.

1. Enumerate the diff or recent commits: producers, consumers, brokers, topics, queues, outbox tables, workflows, schemas, DLQs, retry/backoff config, partition keys, config and secret surfaces.
2. Identify patterns touched: Outbox, Process Manager, Idempotent Receiver, Circuit Breaker, Cache-Aside, Sharding, Saga, CDC, Replay, Backpressure, and any others the change exercises.
3. Identify contracts affected: new event channels, schema changes, compatibility breaks, DLQ ownership shifts, new producer or consumer boundaries.
4. Walk the 8-question reliability checklist with respect to the change — delivery guarantee, idempotency, bad-message strategy, retry policy, ordering, schema evolution, observability, failure boundary — and mark each question as Answered, Open, or Regressed.
5. Walk the distributed-systems checklist when the change touches scale, resilience, multi-region, or service boundaries: ownership, consistency, scaling axis, failure mode, backpressure, operations.
6. Identify anti-patterns introduced or removed: dual-write, ack-before-commit, unbounded retry, retry storm, distributed monolith, shared OLTP, distributed 2PC, oversized broker payloads, missing trace context, autoscaling on the wrong signal, distributed locks without fencing.
7. Compute the readiness-tier impact (Prototype / Service-ready / Production-ready / Enterprise-critical) — does the change move the service up, down, or sideways?

Categorize findings: **Critical** (introduces a launch-blocking anti-pattern or breaks a contract), **Important** (regresses a reliability answer or weakens a contract), **Suggestion** (architecture tightening that is not strictly required). Cite file:line for each finding to ground it.

End with the readiness-tier verdict and the gaps to the next tier (if any).

## Output

This command produces conversational findings, not a file. Use `/architecture` if the user wants a permanent decision artifact, `/ship` for a launch-decision document.
