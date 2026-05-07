---
description: Run a comprehensive launch review and write the go/no-go decision with rollback plan
---

Invoke the `distributed-systems-patterns` skill.

`/prelaunch` runs the `/review` logic (which already covers reliability, distributed-systems checklist, anti-patterns, failure-mode walk, system concerns, and the readiness verdict) and persists the result as a launch decision. Sequential, not fan-out: one comprehensive review, one decision file.

1. Run `/review` against the diff or recent commits. Produce findings categorized as Critical / Important / Suggestion / System; the reliability and distributed-systems checklists; the anti-pattern list; the top 3-5 failure-mode entries with blast radius and mitigation; the readiness tier with gaps.
2. Compute the launch decision. **Default to NO-GO if any Critical findings exist.** The user must explicitly accept the risk to override. Otherwise GO at the tier the review computed.
3. Build the rollback plan: trigger conditions, exact procedure (feature flag flip, halt CDC, drain consumer, schema rollback), and recovery time objective. Mandatory before any GO.
4. Before writing, Glob `docs/features/<slug>/**` to enumerate peer artifacts (design, ADRs, contracts, runbooks, prior launches). Populate `## Related artifacts` with matches; for missing peers, list the conventional path with `(not yet written)`.

## Output

**Write the decision to `docs/features/<slug>/launches/<YYYY-MM-DD>.md`** (today's date in ISO format). Create `docs/features/<slug>/launches/` if it does not exist. Use this structure:

```markdown
## Summary
- **Status**: GO | NO-GO
- **Date**: <YYYY-MM-DD>
- **Feature**: <slug>
- **Tier achieved**: Prototype | Service-ready | Production-ready | Enterprise-critical
- **TL;DR**: 1-sentence rationale for the GO/NO-GO call.

## System concerns
[Carry forward from the review — owner, tenancy, compliance, cost owner, capacity, DR, lifecycle.]

## Launch Decision

### Blockers
[Critical findings from review, with file:line. Must fix before ship.]

### Recommended fixes
[Important findings from review, with file:line. Should fix before ship.]

### Acknowledged risks
[Risks accepted to ship anyway. Each entry: risk + mitigation + accepted-by.]

### Rollback plan
- **Trigger**: <signals that prompt rollback>
- **Procedure**: <exact steps — feature flag flip, halt CDC, drain consumer, schema rollback>
- **RTO**: <target>

## Related artifacts
- Design: `../design.md`
- ADRs: `../adrs/`
- Contracts: `../contracts/`
- Runbooks: `../runbooks/`
- README: `../README.md`
- System catalog: `../../../system/catalog.md`
```

After writing the launch decision, **update the per-feature index and system catalog** in the same turn:
- `docs/features/<slug>/README.md` — append `launches/<YYYY-MM-DD>.md` to `## Artifacts.Launch decisions`. Update `## Service info`: bump `Tier` to the achieved tier (or downgrade if NO-GO) and `Last reviewed` to the launch date. If absent, create from SKILL.md item 16.
- `docs/system/catalog.md` — append/update the row for `<slug>` with new tier and last-reviewed date. If absent, create from SKILL.md item 17.

Emit a one-line confirmation: `Ship decision: <GO|NO-GO>. Written to docs/features/<slug>/launches/<date>.md.` plus blocker count if NO-GO.
