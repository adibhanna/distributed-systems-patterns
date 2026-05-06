---
description: Design an integration or event flow — patterns, modern tools, reliability checklist, written to a design doc
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/decision-tree.md` for problem-to-pattern lookup, `reference/catalog.md` for fuller pattern detail, and `reference/modern-integration-field-guide.md` for modern realizations.

The user has a new integration or event-flow problem. Produce a written design document, not just a chat response.

1. Classify the integration style: File Transfer, Shared Database, Remote Procedure Invocation, or Messaging. State why messaging/distribution is required instead of a simpler local design.
2. Walk `reference/decision-tree.md` to the matching problem branch and name the patterns from `reference/catalog.md` - integration patterns plus distributed-systems patterns when scale, resilience, or boundaries are in play.
3. Run the 8-question reliability checklist from SKILL.md: delivery guarantee, idempotency strategy, bad-message strategy, retry policy, ordering requirement, schema evolution, observability, and failure boundary. No "later" answers.
4. If services, scale, multi-region, or enterprise operations are in scope, also answer the 6-question distributed-systems checklist: ownership, consistency, scaling axis, failure mode, backpressure, operations.
5. Cite the modern realization for each pattern: CloudEvents 1.0, AsyncAPI 3.x, OpenTelemetry, Schema Registry, Debezium/Kafka/SQS/SNS/EventBridge/Pub/Sub/Temporal/Step Functions, KEDA, Envoy/Istio.
6. Flag any anti-pattern visible in the proposed shape: dual-write, ack-before-commit, unbounded retry, retry storm, distributed monolith, shared OLTP across services, distributed 2PC.
7. End with the readiness tier the design currently qualifies for and the gaps to reach Production-ready.

## Output

**Write the design to `docs/designs/<feature-slug>-design.md`** in the current repo. Pick a slug from the user's prompt (e.g. `order-fulfillment`, `webhook-ingestion`). If `docs/` does not exist, create it. If a file with the same name exists, ask before overwriting.

Use this structure:

```markdown
# <Feature> Design

## Integration style
## Patterns
## Reliability checklist (8 answers)
## Distributed-systems checklist (6 answers, when applicable)
## Modern realization
## Anti-patterns to avoid
## Implementation outline
## Readiness tier and gaps
```

Then emit a one-line confirmation in chat: `Design written to docs/designs/<slug>-design.md`. Do not paste the full design back into chat unless the user asks.

If the user explicitly says "show in chat" or "don't write a file", skip the file write and respond conversationally.
