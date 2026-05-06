---
description: Map the change to a readiness tier — Prototype, Service-ready, Production-ready, Enterprise-critical
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/production-guide.md` for the readiness tiers, `reference/maturity-model.md` for the per-level evidence, and `reference/checklist.md` for the gates.

Determine which readiness tier the change actually qualifies for and name the gaps to reach the next tier. Do not call code "production-ready" while reliability or distributed-systems checklist items are unanswered.

1. Gather evidence on the change: tests (unit, idempotency, retry, DLQ, contract, integration, replay), dashboards, alerts, runbook, owner team and escalation path, SLOs at the workflow/user-journey level, capacity plan, security/compliance review, schema CI gate, replay/redrive drill record.
2. Match the evidence against the per-level evidence in `reference/maturity-model.md`: Level 0 Ad hoc / Prototype, Level 1 Pattern-aware / Service-ready basic, Level 2 Reliable service / Service-ready, Level 3 Production-ready, Level 4 Enterprise-critical.
3. Name the current tier explicitly. Cite the specific evidence items that placed it there and the items that prevented a higher tier.
4. List the remaining gaps to reach Production-ready (Level 3) or Enterprise-critical (Level 4) using the recommended-next-move list from `reference/maturity-model.md`.
5. If the author or PR description claims a tier the evidence does not support, state the explicit downgrade and list the missing gates from `reference/checklist.md` and `reference/production-guide.md`.
6. Readiness is not just code-quality. Walk the **system concerns** evidence: ownership (who is paged?), tenancy (how does this isolate?), compliance (what classifications apply?), cost (who pays the bill?), capacity (will this scale?), DR (how does this survive region loss?), lifecycle (when does this retire?). Missing evidence in any concern downgrades the tier.
7. End with the recommended next move and the owner who must close each gap.

## Output

This command produces conversational findings, not a file. If readiness findings reveal owner, tenancy, cost, compliance, capacity, DR, or lifecycle facts that should be persisted, suggest updating `docs/features/<slug>/README.md` accordingly. Do not auto-write; the user owns the persistence decision for analytical findings.
