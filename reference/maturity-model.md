# Distributed Systems Patterns Maturity Model

Use this to assess a team, service, or platform and recommend next steps.

| Level | Name | Description | Typical gaps |
| --- | --- | --- | --- |
| 0 | Ad hoc | Direct broker calls, unclear ownership, no contracts | Dual-write, no DLQ, no idempotency |
| 1 | Pattern-aware | Patterns named and basic reliability questions answered | Manual consistency, weak tests |
| 2 | Reliable service | Outbox/inbox, bounded retries, DLQ, trace context | Weak contract governance, basic ops |
| 3 | Production-ready | Contracts, dashboards, alerts, runbooks, replay/redrive tested | Limited scale/multi-region planning |
| 4 | Enterprise-critical | SLOs, governance, capacity, tenant isolation, progressive delivery | Platform usability/self-service gaps |
| 5 | Paved-road platform | Self-service templates, policy as code, maturity checks, golden paths | Continuous evolution and adoption |

## Assessment questions

- Can every channel be traced to an owner and runbook?
- Can every consumer handle duplicate delivery?
- Can every schema change be compatibility-checked in CI?
- Can DLQ messages be redriven safely?
- Can support answer where a workflow is?
- Are SLOs measured at user journey and workflow level?
- Are scaling and backpressure tested?
- Are security and PII controls enforced by default?

## Recommended next move

- Level 0 -> 1: name patterns, stop dual-writes, document channels.
- Level 1 -> 2: add idempotency, retry/DLQ, trace context, basic tests.
- Level 2 -> 3: add contracts, dashboards, runbooks, redrive/replay drills.
- Level 3 -> 4: add SLOs, capacity, tenant isolation, progressive delivery, governance.
- Level 4 -> 5: build templates, policy checks, self-service docs, evaluation prompts.

See also `reference/production-guide.md` for the readiness tier model these levels map to.
