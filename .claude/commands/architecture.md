---
description: Generate a decision-ready architecture doc, RFC, ADR, or implementation plan with alternatives — written to a file
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/architecture-documentation.md` for the document templates and section requirements, and `reference/architecture-examples.md` for filled ADR/RFC examples.

Produce a decision-ready document file, not a chat dump. The document must help engineers implement and leaders approve.

1. Ask the user to pick the document type: Architecture Overview, RFC / Design Proposal, ADR, Implementation Plan, Migration Plan, Production Readiness Review, or Event Contract Spec. Default to RFC when a decision is not final, ADR when one decision must be recorded.
2. Fill the required sections from `reference/architecture-documentation.md`: Executive Summary, Goals/Non-Goals, Context, Requirements and SLOs, Proposed Architecture, Pattern Mapping, Data and Contracts, Message and Request Flows, Consistency and Transactions, Scale and Performance, Resilience and Failure Modes, Observability and Operations, Security and Compliance, Alternatives Considered, Rollout and Migration Plan, Testing and Verification, Risks and Open Questions.
3. Include the pattern mapping table: `Concern | Pattern | Tool/implementation | Why | Verification`. Name integration patterns and distributed-systems patterns - both, when relevant.
4. Compare at least 2-3 plausible alternatives with explicit trade-offs and the reason each non-recommended option was rejected.
5. Include a rollout/rollback plan: phases, compatibility, dual-write/dual-read if needed, backfill, abort metrics, rollback owner.
6. Add diagrams as Mermaid (flowchart, sequence, state) near the section they explain.
7. Run the architecture review rubric from `reference/architecture-documentation.md` before returning the document: patterns named, owners and boundaries defined, failure paths covered, alternatives and trade-offs shown, rollout/rollback included, operations/security/cost addressed, open questions explicit with owners.
8. Add a `## Summary` block at the top of the produced file with `Status:` (Proposed | Accepted | Superseded), `Date:` (`<YYYY-MM-DD>`), and a 1-2 sentence TL;DR. For ADRs the Status field is part of the standard Nygard structure already; just confirm it is filled in. Immediately after the Summary block, insert a `## System concerns` section with these fields (use `<TBD>` where unspecified): Owner team, Tenancy, Compliance, Cost owner, Capacity, DR posture, Lifecycle.
9. Before writing, decide scope and Glob accordingly. For a feature-scoped doc, Glob `docs/features/<slug>/**` for peer artifacts. For a platform-wide doc, Glob `docs/system/**` plus `docs/features/*/README.md` to surface affected features. Append a `## Related artifacts` section at the bottom that lists matches by relative path; for peers that don't exist yet, list the conventional path with a `(not yet written)` annotation.
10. If the doc supersedes another ADR (e.g. ADR-0007 supersedes ADR-0003), explicitly link the superseded doc in `## Related artifacts` and update the superseded doc's `Status:` to `Superseded by ADR-NNNN`.
11. **Update the per-feature index or system catalog.** After writing the main artifact, also create or update:
    - For a **feature-scoped** artifact: `docs/features/<slug>/README.md` - the per-feature entry point. Append/update the relevant Artifacts subsection (Design / ADRs / Contracts / Runbooks / Launches) with a link to the new artifact. If the file does not exist, create it from the template in SKILL.md item 16. Also append/update the row for `<slug>` in `docs/system/catalog.md`.
    - For a **platform-wide** artifact: append a bullet under the `## Cross-cutting concerns` section of `docs/system/catalog.md` pointing at the new doc. Do not create a per-feature README for platform-wide docs.
    These updates are part of the same command turn; do not leave them for a follow-up.

## Output

**Ask the user up front:** "Is this ADR/RFC platform-wide (cross-feature, e.g. broker choice, schema-registry vendor, mesh policy) or feature-scoped (e.g. saga orchestrator for THIS service)?" Default to feature-scoped if the user's prompt mentions a specific feature; default to platform-wide if it mentions the platform/system as a whole.

**Write the document to a file** under one of these conventional paths:

- Feature-scoped ADR -> `docs/features/<slug>/adrs/NNNN-<title>.md`. NNNN is the next sequential number IN THAT FEATURE'S `adrs/` folder (not global); pad to 4 digits.
- Platform-wide ADR -> `docs/system/adrs/NNNN-<title>.md`. NNNN is the next sequential in `docs/system/adrs/`; pad to 4 digits.
- Feature-scoped RFC / Architecture Overview / Implementation Plan / Migration Plan / Production Readiness Review -> `docs/features/<slug>/architecture-<doctype>.md` (e.g. `architecture-rfc.md`, `architecture-impl-plan.md`).
- Platform-wide RFC / Architecture Overview / Implementation Plan / Migration Plan / Production Readiness Review -> `docs/system/architecture-<doctype>.md`.
- Event Contract Spec -> use `/contract` instead.

Create parent directories if they do not exist. If a file with the chosen name exists, ask before overwriting.

Use these relative paths in the doc's `## Related artifacts` section:

- Feature-scoped ADR at `docs/features/<slug>/adrs/NNNN-<title>.md`:
  - Design: `../design.md`
  - Other ADRs in this feature: `./other-NNNN.md`
  - Contracts: `../contracts/<channel>.md`
  - Per-feature README: `../README.md`
  - Platform ADRs: `../../../system/adrs/`
- Platform-wide ADR at `docs/system/adrs/NNNN-<title>.md`:
  - Catalog: `../catalog.md`
  - Feature READMEs that this ADR affects: `../../features/<slug>/README.md`

**Before returning, run the auto self-check** (SKILL.md item 18): scan for anti-patterns named in Decision/Consequences, verify Status field is filled, refuse all-`<TBD>` system concerns, verify alternatives reference real options and superseded ADRs link back. Critical findings are fixed inline; Important findings are reported in chat.

Emit a one-line confirmation in chat: `<DocType> written to <path>`. Do not paste the full document back into chat. If the user explicitly says "show in chat" or "don't write a file", respond conversationally instead.
