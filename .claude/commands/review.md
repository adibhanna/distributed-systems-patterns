---
description: Production-readiness review on the diff — anti-patterns, reliability gaps, distributed risks
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/checklist.md` for the production review gates and `reference/failure-modes.md` for the failure catalog used to interpret the diff.

Review the staged changes or recent commits as a distributed-systems and integration review. Do not rewrite the change; report findings with file:line references the author can act on.

1. Enumerate the change: producers, consumers, brokers/topics/queues, outbox tables, workflows, schemas, DLQs, retry/backoff config, partition keys, and config/secret surfaces touched.
2. Run the 8-question reliability checklist on the diff: delivery guarantee, idempotency, bad-message strategy, retry policy, ordering, schema evolution, observability, failure boundary.
3. Run the distributed-systems checklist when scale, resilience, multi-region, or service boundaries are touched: ownership, consistency, scaling axis, failure mode, backpressure, operations.
4. Flag every anti-pattern from SKILL.md with file:line: dual-write (`db.Save(); broker.Publish();`), ack/commit before durable side effect, unbounded retry, retry storm across layers, distributed monolith, shared OLTP across services, distributed 2PC, missing trace context, removed/renamed schema fields without compatibility, unbounded queues/goroutines/buffers, autoscaling on the wrong signal, distributed locks without fencing.
5. Categorize each finding as Critical (blocks merge), Important (fix before ship), or Suggestion. Cite file:line for each.
6. State the readiness tier the diff currently qualifies for. If the author claims "production-ready" while reliability or distributed-systems checklist items are unanswered, recommend an explicit downgrade to Service-ready or Prototype and list the gaps.
