# Testing Strategy

Use this when writing or reviewing tests for distributed, messaging, workflow, or enterprise integration code.

## Test pyramid for distributed systems

| Layer | Purpose | Examples |
| --- | --- | --- |
| Unit | Pure mapping, routing, retry classification, idempotency logic | Mapper tests, table-driven retry tests |
| Contract | Producer/consumer schema compatibility | AsyncAPI, Schema Registry, Pact-style event contract |
| Component | Service with fake broker/deps | Outbox write, consumer handler with fake dedup store |
| Integration | Real broker/database/emulator | Testcontainers Kafka/RabbitMQ/Postgres, LocalStack, cloud emulator |
| Workflow replay | Durable workflow determinism and compensation | Temporal workflow tests, Step Functions local/simulator |
| Load/performance | Capacity and bottleneck validation | Hot-key, lag, queue age, p95 latency |
| Chaos/failure | Partial failure behavior | Kill consumer, broker outage, dependency timeout |
| Operational drill | Human/runbook validation | DLQ redrive, replay, failover, rollback |

## Required tests by pattern

| Pattern | Required tests |
| --- | --- |
| Transactional Outbox | Domain row and outbox row commit/rollback together; publisher handles duplicate/out-of-order rows |
| Idempotent Receiver | Same message delivered twice, concurrently if possible, creates one side effect |
| Dead Letter Channel | Poison message reaches DLQ after bounded attempts; source message is not lost before DLQ publish |
| Retry | Transient errors retry with backoff/jitter; permanent errors do not loop |
| Process Manager | Happy path, timeout, activity retry, compensation, cancellation, workflow replay |
| Claim Check | Missing object, wrong checksum, expired object, unauthorized object access |
| Message Translator | v1/v2 compatibility, unknown fields, invalid payload, PII redaction |
| Cache-Aside | Miss, stale hit, invalidation, stampede prevention |
| Circuit Breaker | Opens on failure threshold, half-open recovery, fallback behavior |
| Sharding | Key distribution, hot key, tenant move/backfill, reshard rollback |

## Go testing guidance

- Keep mapper and handler logic behind small interfaces so unit tests do not need a broker.
- Use table-driven tests for retry classification and schema validation.
- Use `context.WithTimeout` in tests that touch I/O.
- Use Testcontainers or local emulators for broker/database integration tests when practical.
- Verify logs/metrics/traces for failure paths when possible.
- Race-test idempotency code if concurrent duplicates are possible.

## CI gates

Minimum production CI:

- `go test ./...`
- schema compatibility check
- contract tests
- lint/static analysis
- integration test suite with broker/database where feasible
- replay/dedup/poison-message tests for messaging code

For enterprise-critical systems:

- load test before launch
- failure injection test
- workflow replay test
- redrive/replay drill
- dependency compatibility check
- security/PII scan

## Test matrix template

| Scenario | Input | Expected behavior | Evidence |
| --- | --- | --- | --- |
| Duplicate event | same `event.id` twice | one side effect, second acked/skipped | idempotency test |
| Poison payload | invalid JSON/schema | DLQ with reason, no infinite retry | DLQ test |
| Downstream timeout | dependency times out | bounded retry then DLQ/alert | retry test |
| Replay old event | retained event replayed | no duplicate external side effect | replay test |
| Hot key | 90% traffic one key | lag visible, no OOM, mitigation documented | load test |
