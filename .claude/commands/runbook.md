---
description: Generate an operational runbook — written to docs/runbooks/<slug>.md
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/operational-runbooks.md` for the runbook templates and quality bar, and `reference/failure-modes.md` to ground the procedure in real failure paths.

A runbook is for a paged engineer at 2am. Be specific, ordered, and safe.

1a. **Determine the runbook scope.** Feature-scoped (default) - the runbook covers an incident affecting one feature/service (e.g. `orders.placed.v1.dlq` triage). Platform-scoped - the runbook covers an incident affecting the platform as a whole (broker cluster outage, schema-registry rollback, region-wide failover orchestrating across all features). Default to feature-scoped if the user names a service or channel; default to platform-scoped if the user mentions broker, mesh, schema-registry, or region-wide events. Honour an explicit `--scope=platform` or `--scope=feature` flag in the user's prompt.

1. Identify the incident type: DLQ triage, consumer lag, stuck workflow, replay/backfill, schema rollback, region failover, or another failure from `reference/failure-modes.md`.
2. Name the owner team, escalation path, paging policy, impacted dashboards (with links/IDs where known), and the related SLOs.
3. State the safety warnings up front: do not paste payloads into chat, do not redrive blindly, stop automatic redrive before triage, restrict replay/redrive permissions to operator role.
4. Provide step-by-step procedure with the structure from `reference/operational-runbooks.md`: triage (identify and classify), mitigation (fix or quarantine), verification (downstream errors, queue age, retry rate, duplicate side effects), and an explicit redrive/replay rate ramp.
5. Define the stop and rollback criteria: what signals abort the procedure, what reverts the change, who decides.
6. Define the audit trail requirements: ticket id, who ran which step, what was redriven, sample payloads handled.
7. Add the post-incident actions: root cause, prevention item (test, alert, code change), runbook update.
8. Validate against the runbook quality bar from `reference/operational-runbooks.md`: owner, dashboards, safety warnings, steps, stop criteria, verification, audit, follow-up.
9. Before writing, run a Glob for `docs/features/<slug>/**` to enumerate peer artifacts. Populate the `## Related artifacts` section with concrete relative paths; for peers that don't exist yet, list the conventional path with a `(not yet written)` annotation.

10. **Update the index for the chosen scope.** After writing the main artifact, also create or update (same command turn, no follow-up):
    - **Feature-scoped**: append/update `Artifacts.Runbooks` in `docs/features/<slug>/README.md` (create from SKILL.md item 16 if missing) and append/update the `<slug>` row in `docs/system/catalog.md` (create from SKILL.md item 17 if missing).
    - **Platform-scoped**: do NOT update a feature README. Instead, append/update the new runbook under the Cross-cutting concerns section of `docs/system/catalog.md` (or bump an existing "Platform runbooks" row).

## Output

Path branches on the scope decided in step 1a. Create the parent directory if it does not exist. If a file with the same name exists, ask before overwriting.

- **Feature-scoped runbook**: `docs/features/<slug>/runbooks/<incident-slug>.md` (e.g. `dlq-triage.md`, `region-failover.md`). Derive the feature slug from the service or channel named in the user's prompt; drop any `<feature>-` filename prefix.
- **Platform-scoped runbook**: `docs/system/runbooks/<incident-slug>.md` (e.g. `broker-cluster-outage.md`, `schema-registry-rollback.md`, `region-wide-failover.md`).

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

Append the Related artifacts variant matching the chosen scope.

Feature-scoped:

```markdown
## Related artifacts
[Paths are relative to `docs/features/<slug>/runbooks/<incident-slug>.md`.]
- Design that introduces the failure path: `../design.md`
- Affected contracts: `../contracts/<channel>.md`
- Per-feature README: `../README.md`
- Failure-mode catalog: `reference/failure-modes.md`
- Other runbooks for adjacent incidents: `./` (siblings)
```

Platform-scoped:

```markdown
## Related artifacts
[Paths are relative to `docs/system/runbooks/<incident>.md`.]
- Catalog: `../catalog.md`
- Platform ADRs: `../adrs/`
- Affected features: `../../features/<slug-1>/README.md`, `../../features/<slug-2>/README.md`, ... (list each feature this runbook affects)
- Failure-mode catalog: `reference/failure-modes.md`
- Other platform runbooks: `./` (siblings)
```

**Before returning, run the auto self-check** (SKILL.md item 18): verify all stop/rollback criteria are concrete (no `<TBD>` triggers), verify owner + escalation + dashboards are named (not placeholder), verify cross-link integrity. Critical findings are fixed inline; Important findings are reported in chat.

Emit a one-line confirmation in chat: `Runbook written to docs/features/<slug>/runbooks/<incident-slug>.md` (feature-scoped) or `Runbook written to docs/system/runbooks/<incident-slug>.md` (platform-scoped). Do not paste the full runbook back into chat. If the user explicitly says "show in chat", respond conversationally instead.
