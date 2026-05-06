---
description: Orchestrate the per-feature pipeline end to end with approval gates. Runs /design -> /contract -> /implement -> /test -> /review -> /failure-mode -> /readiness -> /prelaunch, pausing for user approval between steps.
---

Invoke the `distributed-systems-patterns` skill.

Run the per-feature lifecycle as a single orchestrated flow. After each step writes its artifact (or surfaces its findings), pause and wait for user approval before continuing. This is the smooth path; individual commands stay available for granular control or re-running a single step.

## How the user controls the flow

After each step the user replies with one of:

- `continue` / `yes` / `approve` -> proceed to the next step.
- `revise: <description>` -> update the just-written artifact, then re-pause at the same step.
- `skip <step>` -> bypass an upcoming optional step (e.g. `skip runbook`, `skip architecture`).
- `stop` / `exit` -> leave the pipeline; user can resume by running the next command directly or re-invoking `/build <slug>`.

If the user pre-empts at the start (e.g. `/build payment-authorization, skip runbook`), apply those skip rules without re-asking.

## Lifecycle steps (in order)

For each step, run the logic of the named command (do not invoke the slash command; just perform its work). After the step's artifact is written or its findings are surfaced, emit a one-line confirmation and a pause prompt naming the next step.

### Step 1 - /design (mandatory)
Run /design's logic. Write `docs/features/<slug>/design.md`, update per-feature README and system catalog. Pause: `Design written to docs/features/<slug>/design.md. Reply 'continue' for /contract, or 'revise: <changes>' to update.`

### Step 2 - /contract (per channel named in the design's Boundary contracts section)
For each channel, run /contract's logic. Three files per channel: schema, AsyncAPI, contract doc. Update per-feature README. Pause between channels: `Contract <channel> written. Reply 'continue' for next channel.` After the last channel: `All contracts written. Reply 'continue' for /implement.`

### Step 3 - /architecture (optional)
If the design's Open questions section names decisions that warrant ADRs, ask: `The design has <N> open decisions. Promote to feature-scoped ADRs? Reply 'yes' or 'skip'.` If yes, run /architecture's logic for each.

### Step 4 - /implement (mandatory unless skipped)
Run /implement's logic. Write source files at the paths named in the design's File and component plan section. Annotate pattern boundaries. Pause: `Code written: <file count> files. Reply 'continue' for /test.`

### Step 5 - /test
Run /test's logic. Write test files using the repo's conventional layout. Pause: `Tests written: <test count> tests across <file count> files. Reply 'continue' for /review.`

### Step 6 - /review
Run /review's logic. Surface findings categorized as Critical / Important / Suggestion / System. Pause: `Review complete. <Critical> blockers, <Important> recommendations. Reply 'continue' to proceed (defers fixes to user), 'fix' to address blockers inline, or 'revise' to update earlier artifacts.`

### Step 7 - /runbook (optional, per incident type)
Identify incident types implied by the design's Anti-patterns section and the failure-mode catalog. Ask: `Generate runbooks for: <list>? Reply 'all', 'skip', or name specific ones.`. For each chosen, run /runbook's logic.

### Step 8 - /failure-mode
Run /failure-mode's logic. Pause: `Failure-mode walk complete. <N> failures named with mitigations. Reply 'continue' for /readiness.`

### Step 9 - /readiness
Run /readiness's logic. Pause: `Readiness tier: <tier>. Gaps to next tier: <list>. Reply 'continue' for /prelaunch.`

### Step 10 - /prelaunch
Run /prelaunch's logic. Spawns three subagents (review, failure-mode, readiness) in parallel and synthesizes a launch decision. Writes `docs/features/<slug>/launches/<YYYY-MM-DD>.md`. This is the final step.

## Below-threshold abort

After Step 1 (the design), scan the design's System concerns and Patterns sections. If patterns are empty (no integration / distributed-systems patterns named) and system concerns are mostly `<TBD>` with no compliance / multi-tenancy / multi-region requirement, ask the user: `The design suggests this work is below the threshold for the full pipeline. Abort and answer simply, or proceed anyway?` Stop if user confirms abort.

This is the auto-decline behavior from SKILL.md item 13's threshold check, applied mid-pipeline.

## Output

The orchestrator does not produce its own artifacts. It runs the existing commands' logic in sequence. After all steps complete, emit a final summary:

```
Pipeline complete for <slug>.

Artifacts written:
- Design: docs/features/<slug>/design.md
- Contracts: <channel-list>
- ADRs: <if any>
- Source files: <count>
- Tests: <count>
- Runbooks: <if any>
- Launch decision: docs/features/<slug>/launches/<date>.md

Final tier: <tier>
Decision: <GO/NO-GO>

Next: address any blockers from the launch decision, then re-run /prelaunch to confirm GO.
```

If the user stops mid-pipeline, emit: `Pipeline paused at <step>. Resume with /build <slug> or run the next command directly (e.g. /implement <slug>).`
