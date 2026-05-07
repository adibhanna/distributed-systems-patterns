# Changelog

All notable changes to the `distributed-systems-patterns` skill are recorded here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.2] - 2026-05-07

### Added

Self-check rules expanded to catch classes of issue that human review was previously catching after the fact. SKILL.md item 18 now codifies four reusable claim-rigor rules and two ADR-specific decision-commitment rules; `architecture.md` spells out the 11 ADR self-check items.

**Claim-rigor rules** (any artifact making behavior claims):

- **Concrete-criteria rule** — every "alert if X", "abort gate", "trigger when", "monitor for divergence" claim must name a specific threshold (number, duration, percentage, or named state). `"alert on divergence"` is incomplete; `"alert when end-to-end p99 delta exceeds 30% over a 10-min window"` is acceptable.
- **Per-scope qualification rule** — when a feature owns multiple channels/tenants/regions, behavior claims must be qualified per scope. Generic `"Lost event: not applicable"` is wrong if the feature has channels with differing semantics; split into per-channel claims.
- **Sibling cross-reference rule** — when an artifact says `"covered in <runbook>.md class X"`, Glob to confirm the runbook exists, read its summary, and verify it actually describes class X without contradicting the claim.
- **Pattern-mapping attribution rule** (ADRs/RFCs) — compound rows like `"Bulkhead + circuit breaker"` must split or have the Tool column truthfully attribute each pattern. Don't claim the chosen runtime does something it doesn't (e.g. Temporal does not provide native circuit breakers).

**Decision-commitment rules** (ADRs/RFCs only):

- **No Schrödinger's decision** — Decision sections shaped as `"X with Y as fallback if Z"` are rejected unless they include a documented downgrade trigger naming what would cause the alternative to take over and a decision owner. If the choice cannot be made yet, set `Status: Deferred` and name the blocking question + due date.
- **Open-question / rollout cross-reference** — every open question affecting rollout must be referenced from the rollout phase that depends on it (with due date), and every rollout phase depending on an unresolved choice must name the question that owns the resolution.

### Why

Review of a generated saga-orchestrator ADR surfaced six classes of issue that the v0.6.1 self-check missed: a soft Decision ("X with Y as fallback if Z" without a trigger), a resilience claim that was true for one channel but not another, a pattern-mapping row that overclaimed runtime capabilities, an "alert on divergence" criterion without a threshold, and an open question whose dependency on the rollout was never linked. These are all systematic patterns the agent can detect at write-time. Codifying them in the self-check moves the catch from human review back to the agent's own pre-return pass.

## [0.6.1] - 2026-05-07

### Added

Auto self-check after every artifact-writing command (`/design`, `/contract`, `/architecture`, `/runbook`, `/prelaunch`). Self-check is a 15-30s subset of `/review` focused on inconsistencies the agent should catch in its own work: anti-pattern scan, cross-file consistency, schema-evolution traps (`additionalProperties: false` + BACKWARD), system-concerns completeness, cross-link integrity. Critical findings are fixed inline; Important findings are reported in chat as a `revise:` recommendation.

### Why

Without the inline self-check, simple traps (closed schema + BACKWARD compatibility, channel-name mismatch between design and contract) only got caught when the user ran `/review` later. Adding the self-check moves catch to the same turn, with negligible time cost (1:26 with self-check vs 1:28 without in measured runs).

## [0.6.0] - 2026-05-07

### Removed (BREAKING)

Six commands removed to simplify the skill and refocus on durable decision artifacts:

- `/implement` - competed with the team's actual dev environment (IDE, codegen, framework scaffolding). Generated code with bugs that /review then flagged - wasted cycles. Your team's existing tools do this better.
- `/test` - same problem. Every team has TDD/test frameworks. The skill's fabricated test names were less useful than the team's existing patterns.
- `/build` - orchestrator no longer pulls weight without /implement and /test. The 30-60 min walkthrough was overhead for marginal value.
- `/failure-mode` - folded into /review.
- `/readiness` - folded into /review.
- `/standard` - folded into /architecture at platform scope.

### Changed

- /design output trimmed from 100-150 lines to 60-80 lines. Dropped Modern realization table (the team picks tools), File and component plan (the team owns implementation), Distributed-systems checklist (key answers fold into System concerns).
- /contract doc trimmed from ~100 lines to ~40 lines. Dropped CloudEvents envelope example (lives in the message-contract-template reference), full point-by-point contract checklist (key items fold into slim sections).
- /review absorbs failure-mode and readiness analysis. One conversational review now covers patterns, anti-patterns, failure modes, and tier verdict.
- /prelaunch simplified: runs /review's logic and writes the launch decision. No more parallel-subagent fan-out (with /failure-mode and /readiness gone, the fan-out was vestigial).

### Why

Honest assessment: the v0.5.0 skill went from "decision artifacts to bridge cross-team coordination" to "full pipeline that does the engineering team's job." The first is high-leverage. The second has been done before (Cookiecutter, generators, frameworks) and rarely sticks because every team has its own conventions. The 60+ files generated per feature, 30-60 min runtime, and bugs introduced by /implement (that /review then caught) were signals that /implement and /test were dilutive.

v0.6.0 keeps what's high-leverage: the decision and review layer where teams under-invest. Drops what competes with the team's existing dev environment.

Six commands. ~20 min total per feature. 5-10 files instead of 60. Focused on what humans don't write under deadline pressure but regret missing later.

## [0.3.0] - 2026-05-06

### Changed (BREAKING - path layout)

All artifact paths moved under a per-feature folder. The previous scattered-by-artifact-type layout (docs/designs/, docs/contracts/, schemas/, asyncapi/, docs/runbooks/, docs/launches/, docs/services/) is replaced by `docs/features/<slug>/{design.md,adrs/,contracts/,schemas/,asyncapi/,runbooks/,launches/}`. Each feature now owns one folder containing all its artifacts. Cross-links inside a feature become sibling/child paths instead of `../../...` traversals.

ADRs split into feature-scoped (default, under `docs/features/<slug>/adrs/`) and platform-wide (under `docs/system/adrs/`). NNNN numbering is per-folder.

### Migration

Existing v0.2 installations: run `bash scripts/migrate-layout.sh` from the repo root after updating to v0.3.0. The script moves files into the new layout using `git mv` so history is preserved. Manual review needed afterward to identify which ADRs should move to `docs/system/adrs/` (platform-wide) vs stay under their feature.

### Why

The old layout scattered each feature's artifacts across 5+ root directories. With multiple features the root tree grew unwieldy. The new layout groups everything for one feature in one folder, so a reader can `cd docs/features/<slug>/` and see design + contracts + ADRs + runbooks + launches as siblings.
