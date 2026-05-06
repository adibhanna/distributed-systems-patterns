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
9. Before writing, run a Glob for `docs/designs/<slug>*.md`, `docs/architecture/<slug>*.md`, `docs/adr/*<slug>*.md`, `docs/contracts/<channel>*.md`, `schemas/<channel>*`, `asyncapi/<channel>*.yaml`, `docs/runbooks/*<slug>*.md`, `docs/launches/<slug>*.md`. Append a `## Related artifacts` section at the bottom that lists matches by relative path; for peers that don't exist yet, list the conventional path with a `(not yet written)` annotation.
10. If the doc supersedes another ADR (e.g. ADR-0007 supersedes ADR-0003), explicitly link the superseded doc in `## Related artifacts` and update the superseded doc's `Status:` to `Superseded by ADR-NNNN`.
11. **Update the per-service index and system catalog.** After writing the main artifact, also create or update:
    - `docs/services/<slug>/README.md` - the per-service entry point. Append/update the relevant Artifacts subsection (Design / ADRs / Contracts / Runbooks / Launches) with a link to the new artifact. If the file does not exist, create it from the template in SKILL.md item 16.
    - `docs/system/catalog.md` - the system-level service registry. Append/update the row for `<slug>`. If the file does not exist, create it from the template in SKILL.md item 17.
    If the ADR/RFC is platform-wide rather than service-specific, write the doc under `docs/system/adrs/` or `docs/system/architecture/` and update the `## Cross-cutting concerns` section of `docs/system/catalog.md` instead of a per-service README. These updates are part of the same command turn; do not leave them for a follow-up.

## Output

**Write the document to a file** under one of these conventional paths:

- ADR -> `docs/adr/NNNN-<slug>.md` (use the next sequential number; pad to 4 digits).
- RFC / Architecture Overview / Implementation Plan / Migration Plan / Production Readiness Review -> `docs/architecture/<feature-slug>-<doctype>.md` (e.g. `order-fulfillment-rfc.md`).
- Event Contract Spec -> use `/contract` instead.

Create parent directories if they do not exist. If a file with the chosen name exists, ask before overwriting.

Emit a one-line confirmation in chat: `<DocType> written to <path>`. Do not paste the full document back into chat. If the user explicitly says "show in chat" or "don't write a file", respond conversationally instead.
