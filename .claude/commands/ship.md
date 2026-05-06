---
description: Fan-out parallel review + failure-mode + readiness, synthesize go/no-go with rollback plan
---

Invoke the `distributed-systems-patterns` skill.

`/ship` is a **fan-out orchestrator** for distributed-systems changes. It runs three specialist subagents in parallel against the current diff/PR, then merges their reports into a single go/no-go decision with a rollback plan. The subagents operate independently - no shared state, no ordering - which is what makes parallel execution safe and useful.

## Phase A - Parallel fan-out

Spawn three subagents concurrently using the Agent tool. **Issue all three Agent tool calls in a single assistant turn so they execute in parallel** - sequential calls defeat the purpose of this command.

1. **Review** - Run the `/review` command's logic on the staged changes or recent commits: 8-question reliability checklist, distributed-systems checklist, anti-pattern flags, file:line findings. Output the standard review template.
2. **Failure-mode** - Run the `/failure-mode` command's logic against the change's design surface: first failure, worst duplicate, blocked partition, retry storm, replay safety. Output the 8 review questions answered.
3. **Readiness** - Run the `/readiness` command's logic: current tier, evidence, gaps to Production-ready or Enterprise-critical. Output the tier assessment.

Each subagent gets its own context window and returns only its report. Subagents cannot spawn other subagents.

If `code-reviewer`, `security-auditor`, `test-engineer` subagent types are available in the harness, use them; otherwise spawn `general-purpose` and explicitly load the relevant `reference/*.md` files in the prompt.

## Phase B - Merge in main context

Once all three reports are back, the main agent (not a sub-persona) synthesizes:

1. Promote any Critical reliability or anti-pattern findings to launch blockers.
2. Cross-reference failure-mode findings with the review's anti-pattern list - duplicates collapse, gaps surface.
3. Cross-reference readiness gaps with the review's checklist gaps - they should agree; if they don't, name the disagreement.
4. Compute the readiness tier the change actually qualifies for (downgrade if necessary).

## Phase C - Decision and rollback

Produce a single output:

```markdown
## Ship Decision: GO | NO-GO

### Tier
[Prototype | Service-ready | Production-ready | Enterprise-critical]

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

### Subagent reports (full)
- [Review report]
- [Failure-mode report]
- [Readiness report]
```

## Rules

1. The three Phase A subagents run in parallel - never sequentially.
2. Subagents do not call each other. The main agent merges in Phase B.
3. The rollback plan is mandatory before any GO decision.
4. If any subagent flags a Critical anti-pattern (dual-write, ack-before-commit, unbounded retry, retry storm, distributed monolith), the default verdict is NO-GO unless the user explicitly accepts the risk.
5. **Skip the fan-out only if all of:** the change touches 2 files or fewer, the diff is under 50 lines, and it does not touch a producer/consumer/broker config, an outbox, a workflow, a schema, a DLQ, or auth. Otherwise default to fan-out.
