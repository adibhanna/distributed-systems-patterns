---
description: Write a platform standard / convention doc that every feature must follow
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/distributed-systems-guide.md` for governance and standards framing, and `reference/security-compliance.md` if the standard touches security/PII/compliance.

A standard is a rule every feature in the system follows. It belongs to the platform team, not any single feature. Write it tightly so feature artifacts can reference it instead of restating.

1. Determine the topic slug from the user's prompt (kebab-case, single concept: `observability`, `channel-naming`, `security-baseline`, `deployment`, `slo-policy`).
2. State the rule in one sentence. The rule should be testable: a feature either complies or doesn't.
3. List concrete requirements (numbered or bulleted) that a feature must satisfy.
4. List enforcement: how the standard is checked (CI gate, peer review, audit, manual review).
5. List exceptions: when a feature may diverge, who approves, how the divergence is documented.
6. Cross-link to relevant ADRs that establish the standard.

## Output

Write the standard to `docs/system/standards/<topic>.md`. Create `docs/system/standards/` if absent. If a file with the same name exists, ask before overwriting.

Use this template:

```markdown
# Platform Standard: <Topic Title>

## Summary
- **Status**: Draft | Active | Deprecating | Retired
- **Date**: <YYYY-MM-DD>
- **Owner**: <platform team / on-call / approving authority>
- **Applies to**: All features under `docs/features/`, unless an explicit exception is documented.
- **TL;DR**: 1-sentence statement of the rule.

## Rule
[The single-sentence statement of the rule that every feature must follow.]

## Requirements
[Numbered list of concrete, testable requirements. Each one is a bullet a feature can be checked against.]

## Enforcement
- **CI gate**: <yes/no - which check>
- **Review gate**: <where/when this is checked, e.g. /review command, PR template>
- **Audit cadence**: <quarterly / per-launch / never>

## Exceptions
[How a feature may diverge: who approves, where the divergence is documented (typically the feature's per-feature README under `## System concerns` with a link back to this standard).]

## Related artifacts
- ADRs that establish or modify this standard: `../adrs/`
- Feature READMEs that explicitly opt out or have exceptions: list them.
- Platform-level catalog: `../catalog.md`
```

After writing, update `docs/system/catalog.md` Cross-cutting concerns section with a link to the new standard. Create `docs/system/catalog.md` if it does not exist.

Emit a one-line confirmation in chat: `Standard written to docs/system/standards/<topic>.md`. Do not paste the standard back into chat.
