---
description: Fan-out parallel review + failure-mode + readiness, synthesize go/no-go with rollback plan
---

Invoke the `distributed-systems-patterns` skill.

`/ship` is a **fan-out orchestrator** for distributed-systems changes. It runs three specialist subagents in parallel against the diff/PR, then merges their reports into a single go/no-go with a rollback plan.

## Phase A - Parallel fan-out

Spawn three subagents concurrently. **Issue all three Agent tool calls in a single assistant turn** - sequential calls defeat the purpose.

1. **Review** - Run `/review` logic: 8-question reliability checklist, distributed-systems checklist, anti-pattern flags, file:line findings.
2. **Failure-mode** - Run `/failure-mode` logic: first failure, worst duplicate, blocked partition, retry storm, replay safety. Output the 8 review questions answered.
3. **Readiness** - Run `/readiness` logic: current tier, evidence, gaps to Production-ready or Enterprise-critical.

Each subagent gets its own context window and cannot spawn other subagents. If `code-reviewer`, `security-auditor`, `test-engineer` subagent types are available, use them; otherwise spawn `general-purpose` and load the relevant `reference/*.md` files in the prompt.

## Phase B - Merge in main context

1. Promote Critical reliability or anti-pattern findings to launch blockers.
2. Cross-reference failure-mode findings with review's anti-pattern list - duplicates collapse, gaps surface.
3. Cross-reference readiness gaps with review's checklist gaps - if they disagree, name the disagreement.
4. Compute the readiness tier the change actually qualifies for (downgrade if necessary).

## Phase C - Decision and rollback

Before writing, Glob `docs/designs/*<slug>*.md`, `docs/architecture/*<slug>*.md`, `docs/adr/*<slug>*.md`, `docs/contracts/*<slug>*.md`, `docs/runbooks/*<slug>*.md` and populate `## Related artifacts` with matches; for missing peers, list the conventional path with `(not yet written)`.

After writing the launch decision, **update the per-service index and system catalog** in the same turn:
- `docs/services/<slug>/README.md` - per-service entry point. Append/update `Artifacts.Launch decisions` with a link to the new launch doc, and update `## Service info`: bump `Tier` to the achieved tier (or downgrade if NO-GO) and `Last reviewed` to the launch date. If absent, create from SKILL.md item 16.
- `docs/system/catalog.md` - system-level service registry. Append/update the row for `<slug>` with new tier and last-reviewed date. If absent, create from SKILL.md item 17.

**Write the decision to `docs/launches/<feature-slug>-<YYYY-MM-DD>.md`** (today's date in ISO format). Create `docs/launches/` if it does not exist. Use this structure:

```markdown
## Summary
- **Status**: GO | NO-GO
- **Date**: <YYYY-MM-DD>
- **Feature**: <slug>
- **Tier achieved**: Prototype | Service-ready | Production-ready | Enterprise-critical
- **TL;DR**: 1-sentence rationale for the GO/NO-GO call.

## System concerns
- **Owner team**: <team / Slack / on-call escalation>
- **Tenancy**: <single-tenant | multi-tenant w/ specified isolation>
- **Compliance**: <none | PII | GDPR | SOC2 | PCI | data residency>
- **Cost owner**: <team / cost center / per-event budget>
- **Capacity**: <expected p50/p99 volume; growth assumption>
- **DR posture**: <RPO | RTO | region strategy>
- **Lifecycle**: <creation date; deprecation trigger; replacement plan>

## Ship Decision
### Blockers (must fix before ship)
- [Source subagent: Critical finding + file:line]
### Recommended fixes (should fix before ship)
- [Source subagent: Important finding + file:line]
### Acknowledged risks (shipping anyway)
- [Risk + mitigation]
### Rollback plan
- Trigger conditions: [signals that prompt rollback]
- Rollback procedure: [exact steps - feature flag flip, redrive halt, schema revert, etc.]
- Recovery time objective: [target]

## Related artifacts
- Design: `docs/designs/<slug>-design.md`; ADRs: `docs/adr/*<slug>*.md`; Contracts: `docs/contracts/`; Runbooks: `docs/runbooks/`.
- Failure-mode notes: inline above (capture key findings in Acknowledged risks if shipping despite them).

### Subagent reports (full)
- [Review report] / [Failure-mode report] / [Readiness report]
```

Emit a one-line confirmation: `Ship decision: <GO|NO-GO>. Written to docs/launches/<slug>-<date>.md.` plus blocker count if NO-GO.

## Rules

1. Phase A subagents run in parallel - never sequentially. Subagents do not call each other; the main agent merges in Phase B.
2. The rollback plan is mandatory before any GO decision.
3. If any subagent flags a Critical anti-pattern (dual-write, ack-before-commit, unbounded retry, retry storm, distributed monolith), the default verdict is NO-GO unless the user accepts the risk.
4. **Skip the fan-out only if all:** change touches 2 files or fewer, diff under 50 lines, does not touch a producer/consumer/broker config, outbox, workflow, schema, DLQ, or auth.
