# Operational Runbooks

Use this when generating runbooks, launch checklists, incident docs, or production-readiness material.

## DLQ triage runbook

1. Identify channel, owner, first failure time, and current DLQ depth/age.
2. Sample messages safely; do not paste sensitive payloads into tickets/chat.
3. Group by event type, schema version, error reason, producer, tenant, and consumer version.
4. Classify transient vs permanent.
5. Stop automatic redrive if enabled.
6. Fix code/config/schema or quarantine unrecoverable messages.
7. Redrive a small sample at low rate.
8. Monitor downstream errors, queue age, retry rate, saturation, and duplicate side effects.
9. Increase redrive gradually.
10. Record root cause and prevention item.

## Consumer lag incident runbook

1. Confirm lag age, not only count.
2. Identify partitions/shards/keys with highest lag.
3. Check consumer errors, retry rate, DLQ depth, and downstream dependency latency.
4. Check recent deploys and schema changes.
5. If downstream is slow, reduce concurrency or open circuit breaker instead of retrying harder.
6. If hot key, isolate or shard if possible.
7. Scale consumers only if partitions and downstream capacity allow it.
8. Communicate user/business impact and ETA.

## Stuck workflow runbook

1. Query workflow state by business id.
2. Identify current activity/state, attempt count, timeout, and last error.
3. Check dependency health.
4. Decide retry, cancel, compensate, or manual intervention.
5. Ensure idempotency before re-running activities.
6. Record workflow id and audit action.

## Replay/backfill runbook

1. Define event range, channel, tenants, and expected volume.
2. Confirm consumers are replay-safe.
3. Disable or guard external side effects if needed.
4. Run sample replay in staging or shadow mode.
5. Start production replay at low rate.
6. Monitor lag/age, errors, DLQ, downstream saturation, and business counters.
7. Pause on anomaly.
8. Verify final counts and reconciliation.

## Schema rollback runbook

1. Identify incompatible field/version and affected consumers.
2. Stop producer rollout.
3. Restore previous schema or publish compatibility patch.
4. Redrive failed messages only after consumers can parse them.
5. Add schema compatibility test that would have caught the issue.

## Region failover drill

1. Name RPO/RTO target and failover owner.
2. Freeze non-essential deployments.
3. Confirm backup/replica/event bridge health.
4. Shift traffic according to runbook.
5. Verify producers, consumers, workflows, dedup stores, and dashboards.
6. Watch duplicate delivery and ordering changes.
7. Execute failback plan and reconcile.

## Runbook quality bar

Every runbook should include:

- Owner and escalation.
- Impacted systems and dashboards.
- Safety warnings.
- Step-by-step actions.
- Stop/rollback criteria.
- Verification.
- Audit trail requirements.
- Post-incident follow-up.
