# Failure Mode Catalog

Use this during design reviews, PR reviews, incident debugging, and architecture documents. Distributed systems fail by default; the design must say how.

| Failure mode | Common cause | Impact | Patterns / mitigations | Tests |
| --- | --- | --- | --- | --- |
| Duplicate delivery | At-least-once broker, retry after ack timeout, redrive | Double charge, duplicate email, inventory drift | Idempotent Receiver, inbox table, natural idempotency | Deliver same message twice concurrently |
| Out-of-order delivery | Partition key mismatch, redrive, multi-region bridge | Invalid state transition | Per-key ordering, version checks, Resequencer | Reorder lifecycle events |
| Lost publish | DB commit followed by broker failure | Downstream never sees state change | Transactional Outbox + CDC | Crash after DB commit before publish |
| Ack before commit | Auto-commit or delete before side effect | Message lost after consumer crash | Commit after durable work | Crash between ack and DB write |
| Poison message loop | Invalid payload repeatedly retried | Lag, cost, blocked partition | Invalid Message Channel, DLQ, bounded retry | Malformed payload routes to DLQ |
| Retry storm | Many clients retry same outage | Cascading failure | Retry budget, backoff, jitter, circuit breaker | Dependency returns 503 under load |
| Hot partition | Bad partition key or large tenant | Lag and throttling for one shard/key | Better key, tenant isolation, resharding | Load test skewed key distribution |
| Stale cache | TTL too long, missing invalidation | User sees wrong data | Cache policy, event invalidation, read-your-writes path | Update then read through cache |
| Cache stampede | Popular key expires | DB overload | Singleflight, jittered TTL, request coalescing | Expire hot key under load |
| Split brain | Multi-region/leader failover bug | Conflicting writes | Single writer, lease + fencing, conflict policy | Simulate partition/failover |
| Zombie lock holder | Paused process resumes after lease expiry | Stale write overwrites newer state | Fencing token | Force lease expiry then stale write |
| DLQ privacy leak | Sensitive payload lands in DLQ/log | Compliance incident | Redaction, encryption, PII schema tags | PII scan on DLQ/log sample |
| Lost trace context | Headers not propagated | Un-debuggable incidents | Message History, W3C Trace Context | Trace across producer/broker/consumer |
| Replay side effect | Backfill sends emails/charges again | Customer/business harm | Replay mode, idempotency, side-effect guards | Replay old events in staging |
| Consumer memory blow-up | Unbounded batch/prefetch/goroutines | OOM and redelivery loop | Bounded workers, prefetch limits, backpressure | Load test with slow downstream |
| Schema drift | Producer changes field type/name | Consumers fail | Schema Registry, compatibility CI | Incompatible schema fails build |
| Clock skew | TTL/expiry/lease uses local clocks | Premature expiry or stale locks | Server-side clocks, leases with fencing | Simulate skew where possible |
| Region failover duplicate | Active-passive replay or active-active bridge | Duplicate side effects | Idempotency, conflict policy, replay-safe consumers | Failover/failback drill |

## Review questions

- What is the first failure this design will see in production?
- What is the worst duplicate side effect?
- What is the worst stale-read consequence?
- What can block a partition/shard/key?
- What happens when the downstream is slow but not down?
- Can replay/backfill be run without external side effects?
- Where do bad messages go and who is paged?
- Which failures are safe to retry and which must stop?
