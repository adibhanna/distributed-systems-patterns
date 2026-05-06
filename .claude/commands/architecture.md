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

## Output

**Write the document to a file** under one of these conventional paths:

- ADR -> `docs/adr/NNNN-<slug>.md` (use the next sequential number; pad to 4 digits).
- RFC / Architecture Overview / Implementation Plan / Migration Plan / Production Readiness Review -> `docs/architecture/<feature-slug>-<doctype>.md` (e.g. `order-fulfillment-rfc.md`).
- Event Contract Spec -> use `/contract` instead.

Create parent directories if they do not exist. If a file with the chosen name exists, ask before overwriting.

Emit a one-line confirmation in chat: `<DocType> written to <path>`. Do not paste the full document back into chat. If the user explicitly says "show in chat" or "don't write a file", respond conversationally instead.
