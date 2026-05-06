---
description: Generate an operational runbook — written to docs/runbooks/<slug>.md
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/operational-runbooks.md` for the runbook templates and quality bar, and `reference/failure-modes.md` to ground the procedure in real failure paths.

A runbook is for a paged engineer at 2am. Be specific, ordered, and safe.

1. Identify the incident type: DLQ triage, consumer lag, stuck workflow, replay/backfill, schema rollback, region failover, or another failure from `reference/failure-modes.md`.
2. Name the owner team, escalation path, paging policy, impacted dashboards (with links/IDs where known), and the related SLOs.
3. State the safety warnings up front: do not paste payloads into chat, do not redrive blindly, stop automatic redrive before triage, restrict replay/redrive permissions to operator role.
4. Provide step-by-step procedure with the structure from `reference/operational-runbooks.md`: triage (identify and classify), mitigation (fix or quarantine), verification (downstream errors, queue age, retry rate, duplicate side effects), and an explicit redrive/replay rate ramp.
5. Define the stop and rollback criteria: what signals abort the procedure, what reverts the change, who decides.
6. Define the audit trail requirements: ticket id, who ran which step, what was redriven, sample payloads handled.
7. Add the post-incident actions: root cause, prevention item (test, alert, code change), runbook update.
8. Validate against the runbook quality bar from `reference/operational-runbooks.md`: owner, dashboards, safety warnings, steps, stop criteria, verification, audit, follow-up.

## Output

**Write the runbook to `docs/runbooks/<incident-slug>.md`** (e.g. `dlq-triage-orders-placed-v1.md`, `region-failover.md`). Create `docs/runbooks/` if it does not exist. If a file with the same name exists, ask before overwriting.

Emit a one-line confirmation in chat: `Runbook written to docs/runbooks/<slug>.md`. Do not paste the full runbook back into chat. If the user explicitly says "show in chat", respond conversationally instead.
