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
9. Before writing, run a Glob for `docs/designs/*<slug>*.md`, `docs/architecture/*<slug>*.md`, `docs/adr/*<slug>*.md`, `docs/contracts/*<channel>*.md`, `schemas/<channel>*`, `asyncapi/<channel>*.yaml`, `docs/runbooks/*<slug>*.md`, `docs/launches/<slug>*.md`. Populate the `## Related artifacts` section with concrete relative paths; for peers that don't exist yet, list the conventional path with a `(not yet written)` annotation.

10. **Update the per-service index and system catalog.** After writing the main artifact, also create or update:
    - `docs/services/<slug>/README.md` - the per-service entry point. Append/update the `Artifacts.Runbooks` subsection with a link to the new runbook. If the file does not exist, create it from the template in SKILL.md item 16.
    - `docs/system/catalog.md` - the system-level service registry. Append/update the row for `<slug>`. If the file does not exist, create it from the template in SKILL.md item 17.
    These updates are part of the same command turn; do not leave them for a follow-up.

## Output

**Write the runbook to `docs/runbooks/<incident-slug>.md`** (e.g. `dlq-triage-orders-placed-v1.md`, `region-failover.md`). Create `docs/runbooks/` if it does not exist. If a file with the same name exists, ask before overwriting.

Prepend:

```markdown
## Summary
- **Status**: Draft | Active | Retired
- **Date**: <YYYY-MM-DD>
- **Incident type**: <DLQ triage | consumer lag | replay | failover | schema rollback | stuck workflow>
- **Owner**: <team/escalation/page-target>
- **TL;DR**: 1-sentence statement of what this runbook covers and when to invoke it.

## System concerns
- **Owner team**: <team / Slack / on-call escalation>
- **Tenancy**: <single-tenant | multi-tenant w/ specified isolation>
- **Compliance**: <none | PII | GDPR | SOC2 | PCI | data residency>
- **Cost owner**: <team / cost center / per-event budget>
- **Capacity**: <expected p50/p99 volume; growth assumption>
- **DR posture**: <RPO | RTO | region strategy>
- **Lifecycle**: <creation date; deprecation trigger; replacement plan>
```

Append:

```markdown
## Related artifacts
- Design that introduces the failure path: `docs/designs/<slug>-design.md`
- Affected contracts: `docs/contracts/<channel>.md`
- Failure-mode catalog: `reference/failure-modes.md`
- Other runbooks for adjacent incidents: `docs/runbooks/`
```

Emit a one-line confirmation in chat: `Runbook written to docs/runbooks/<slug>.md`. Do not paste the full runbook back into chat. If the user explicitly says "show in chat", respond conversationally instead.
