---
description: Failure-mode analysis — first production failure, worst duplicate, blocked partition, retry storm
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/failure-modes.md` for the failure catalog and the 8 review questions used to interpret the design.

Walk the failure-mode catalog against the current design or diff. Distributed systems fail by default; the design must say how.

1. Read the design (or current diff): producers, consumers, brokers, workflows, schemas, DLQs, retry config, partition keys, caches, cross-region paths.
2. List the 5-7 failures from `reference/failure-modes.md` most likely to bite this design first. Skip failures that are not reachable from the current shape.
3. For each named failure, give: root cause as it applies here, blast radius and impact (user, business, data), mitigation patterns from the catalog, and the test that would prove the mitigation works (duplicate-delivery, poison-message, replay, failover, hot-key load test, etc.).
4. Answer the 8 review questions from `reference/failure-modes.md`: first failure in production, worst duplicate side effect, worst stale-read consequence, what blocks a partition/shard/key, what happens when downstream is slow but not down, can replay/backfill run without external side effects, where bad messages go and who is paged, which failures are safe to retry vs must stop.
5. Flag any anti-pattern observed: ack-before-commit, dual-write, unbounded retry, retry storm, missing fencing, missing idempotency, missing trace propagation, replay-unsafe side effects.
6. Output the prioritized list of mitigations the design must add before reaching Production-ready, ranked by impact-times-likelihood.
