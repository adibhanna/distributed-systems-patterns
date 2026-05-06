# Distributed Systems Patterns Maturity Model

Use this when assessing a team, service, or platform's maturity. For per-code-change readiness gating, use the readiness tiers in `reference/production-guide.md` - they share these names and are checked against the same evidence.

## Unified levels

| Level | Maturity name        | Readiness tier        | Summary                                                                              |
| ----- | -------------------- | --------------------- | ------------------------------------------------------------------------------------ |
| 0     | Ad hoc               | Prototype             | Pattern named, code compiles. Reliability questions answered in design notes only.   |
| 1     | Pattern-aware        | Service-ready (basic) | Outbox/inbox, idempotency, bounded retry, DLQ wired. Safe for shared dev/staging.    |
| 2     | Reliable service     | Service-ready         | Tests for idempotency, retry, DLQ, replay. Trace context propagated. Basic dashboard.|
| 3     | Production-ready     | Production-ready      | Contracts in CI, real-broker integration test, dashboards, alerts, runbook, owner, replay/redrive drilled. Safe for customer traffic. |
| 4     | Enterprise-critical  | Enterprise-critical   | SLOs measured, capacity tested, security/compliance reviewed, DR plan, tenant isolation, progressive delivery. Regulated or revenue-critical paths. |
| 5     | Paved-road platform  | (organization-level)  | Templates, policy-as-code, golden paths, automated maturity checks, self-service.    |

Levels 0-4 are per-service or per-code-change. Level 5 is a platform-team capability and does not correspond to a per-service readiness tier.

## Per-level evidence

- **Level 0 - Ad hoc**
  - Pattern is named in code or design doc.
  - Code compiles and runs against a local broker or stub.
  - Reliability questions (idempotency, retry, ordering, DLQ) answered in comments or design notes.
  - No production deploy.

- **Level 1 - Pattern-aware**
  - Outbox or inbox wired for cross-service writes; no dual-writes.
  - Idempotency key on every consumer side effect.
  - Bounded retry with explicit backoff and a real DLQ.
  - Channels documented with owner and purpose.
  - Safe to deploy to shared dev or staging.

- **Level 2 - Reliable service**
  - Unit tests cover idempotent replay, retry classification, DLQ routing.
  - OpenTelemetry trace context injected/extracted on every broker hop.
  - Basic metrics dashboard: queue age, DLQ depth, retry rate, throughput.
  - Schema location and compatibility mode declared.
  - Graceful shutdown and ack-after-durable-write enforced.

- **Level 3 - Production-ready**
  - AsyncAPI/schema contracts checked for compatibility in CI.
  - Integration test against a real broker covering at least one success and one poison path.
  - Dashboards, alerts (DLQ first message, retry deviation, queue age), and runbook published.
  - Named owner team and on-call escalation path.
  - Replay and redrive procedures drilled (not just documented).
  - Safe for customer traffic.

- **Level 4 - Enterprise-critical**
  - SLOs measured at workflow and user-journey level, not just per broker.
  - Capacity plan with tested burst and dependency-quota headroom.
  - Security and compliance review: PII classified, encryption, ACLs, audit trail.
  - Disaster recovery plan with tested RPO/RTO and game-day evidence.
  - Tenant isolation: quotas, noisy-neighbor protection, per-tenant observability.
  - Progressive delivery with abort metrics and named rollback owner.

## Level 5 note

Paved-road platform is an organization-level capability, not a state any single service occupies. It describes what the platform team offers to product teams: scaffold templates wired with outbox/inbox/DLQ defaults, policy-as-code that fails CI on missing contracts or owners, golden paths for the common broker choices, automated maturity checks, and self-service portals for channel registration and runbook publication. A service consuming the paved road can still be at any of levels 0-4.

## Recommended next move

- Level 0 -> 1: name patterns, stop dual-writes, wire outbox/inbox, idempotency, bounded retry, DLQ.
- Level 1 -> 2: add tests for idempotency/retry/DLQ/replay, propagate trace context, ship a basic dashboard.
- Level 2 -> 3: add contract CI, real-broker integration test, alerts, runbook, named owner, replay/redrive drill.
- Level 3 -> 4: measure SLOs, capacity test, security/DR review, tenant isolation, progressive delivery.
- Level 4 -> 5: extract templates, policy-as-code, golden paths, automated maturity checks, self-service docs.

See `reference/production-guide.md` for the readiness gating angle - same evidence, framed as per-code-change tiers.
