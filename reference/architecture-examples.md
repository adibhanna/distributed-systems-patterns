# Architecture Examples

Use these as style references when generating docs. Keep examples concise and adapt them to the user's domain.

## ADR: Use Transactional Outbox For Order Events

```markdown
# ADR-001: Use Transactional Outbox For Order Events

## Status
Accepted

## Context
The Orders service must persist orders and publish `orders.placed.v1` for inventory, fulfillment, and analytics. Directly committing the database and then publishing to Kafka creates a dual-write failure window.

## Decision
Orders will write an outbox row in the same Postgres transaction as the order. Debezium will publish the outbox row to Kafka as a CloudEvents message.

## Consequences
Positive:
- No lost event when the API crashes after DB commit.
- Events are replayable from the outbox/stream.
- Producers do not need broker availability on the request path.

Negative:
- Debezium connector lag must be monitored.
- Outbox schema and cleanup need ownership.

## Alternatives Considered
- Direct Kafka publish after DB commit: rejected due to dual-write.
- Kafka transaction only: rejected because the business write is in Postgres.

## Verification
- Test order and outbox row commit/rollback together.
- Alert on outbox connector lag.
- Duplicate event delivery test for consumers.
```

## ADR: Use Process Manager For Refund Workflow

```markdown
# ADR-002: Use Temporal Process Manager For Refunds

## Status
Proposed

## Context
Refunds coordinate payment provider calls, ledger updates, customer notification, and support visibility. Pure event choreography would spread state across handlers and make support queries difficult.

## Decision
Use Temporal as a Process Manager. Activities will be idempotent by refund id. The workflow will model timeout, retry, compensation, and terminal states.

## Consequences
Positive:
- Queryable workflow state.
- Durable retries and compensation.
- Replayable history for debugging.

Negative:
- Temporal operational knowledge required.
- Workflow code must remain deterministic and versioned.

## Alternatives Considered
- Pure choreography: rejected due to hidden state machine.
- Single synchronous API chain: rejected due to cascading failure risk.

## Verification
- Workflow replay test.
- Payment timeout test.
- Compensation test.
- Support query dashboard.
```

## RFC skeleton: Event Bus Platform

```markdown
# RFC: Multi-Tenant Event Bus Platform

## Summary
Build a tenant-aware event bus with semantic channels, CloudEvents envelopes, schema compatibility, per-tenant quotas, DLQ ownership, and replay controls.

## Recommendation
Use Kafka/Redpanda for core event streams, Schema Registry for contracts, and a self-service catalog for producers/consumers.

## Pattern Mapping
| Concern | Pattern | Implementation |
| --- | --- | --- |
| Fan-out | Publish-Subscribe Channel | Topic + consumer groups |
| Event typing | Datatype Channel | One event type per topic |
| Contracts | Canonical Data Model | CloudEvents + schema registry |
| Tenant isolation | Quotas + Sharding | per-tenant quotas and partition strategy |

## Open Questions
- Required tenant isolation tier?
- Retention by event class?
- Cross-region replay requirements?
```
