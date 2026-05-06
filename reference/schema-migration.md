# Schema Migration

Use this when an event contract needs to change and consumers exist that you cannot redeploy in lockstep with the producer. The goal is to evolve the schema without a flag-day, without silent data loss, and without consumers blocked on a release they did not ask for.

## The six categories of schema change

| Change                              | Safe path                                                                | New channel version required? |
| ----------------------------------- | ------------------------------------------------------------------------ | ----------------------------- |
| Add optional field                  | Ship in `v1`. Old consumers ignore it. Default value is required.        | No                            |
| Add required field                  | Treat as breaking. Add as optional in `v1`, then introduce `v2`.         | Yes                           |
| Rename field                        | Dual-write old + new in `v1`, then introduce `v2` with only the new.     | Yes                           |
| Change field type                   | Always breaking unless registry compatibility allows widening (int->long). | Usually yes                   |
| Remove field                        | Mark deprecated in `v1`, audit consumers, retire field only in `v2`.     | Yes                           |
| Change semantic meaning, same name  | Always breaking. Same field name with new meaning is a silent data bug.  | Yes, no exceptions            |

The default question to ask: "Could a consumer that was deployed against the old schema, with no code change, still process the new payload correctly?" If the answer is anything other than "yes", you are introducing `v2`.

## The five-phase rollout for a breaking change

1. **Define `v2`** in the registry / AsyncAPI. Publish the schema diff to consumer owners. No producer change yet.
2. **Producer dual-publishes** `v1` and `v2` to separate channels. Same source of truth, two payload shapes. Run for the agreed migration window — typically 60-90 days for external partners, 14-30 days for internal teams.
3. **Consumers migrate to `v2` one at a time.** Each consumer team owns its own move. Track progress in an audit table.
4. **Producer announces deprecation** for `v1` with a fixed retirement date. Continue dual-publish until the date.
5. **`v1` channel and topic are retired.** Close ACLs, stop the producer's `v1` write path, archive remaining `v1` data per retention policy.

A consumer-audit gate runs at every phase. Phase 4 cannot start until every consumer in the audit table is on `v2` or has signed off on receiving its last `v1` event.

## Worked example: rename `customer_id` to `account_id`

Original `orders.placed.v1`:

```json
{
  "specversion": "1.0",
  "type": "com.acme.orders.placed.v1",
  "data": {
    "order_id": "ord_123",
    "customer_id": "cus_456",
    "total_cents": 4999
  }
}
```

New `orders.placed.v2`:

```json
{
  "specversion": "1.0",
  "type": "com.acme.orders.placed.v2",
  "data": {
    "order_id": "ord_123",
    "account_id": "acc_456",
    "total_cents": 4999
  }
}
```

Schema diff (Avro):

```json
{
  "v1": { "name": "customer_id", "type": "string" },
  "v2": { "name": "account_id",  "type": "string" }
}
```

Dual-publish window: 90 days. Producer code:

```go
// Pattern: Datatype Channel - one event type per topic, versioned.
func (p *Publisher) PublishOrderPlaced(ctx context.Context, o Order) error {
    if err := p.publish(ctx, "orders.placed.v1", v1Payload(o)); err != nil {
        return err
    }
    return p.publish(ctx, "orders.placed.v2", v2Payload(o))
}
```

Audit table:

| Consumer            | Owner team    | Current version | Target version | Status        |
| ------------------- | ------------- | --------------- | -------------- | ------------- |
| inventory-reserver  | inventory     | v1              | v2             | done          |
| billing-ledger      | billing       | v1              | v2             | in progress   |
| analytics-loader    | data          | v1              | v2             | not started   |
| partner-export      | integrations  | v1              | v1 (frozen)    | sign-off      |

`partner-export` will keep reading `v1` until partners migrate. The producer commits to a `v1` retirement date only after `partner-export` clears its sign-off.

## Compatibility modes

| Mode      | Producer can                          | Consumer must                                | Use when                                                |
| --------- | ------------------------------------- | -------------------------------------------- | ------------------------------------------------------- |
| BACKWARD  | Add optional fields, remove required  | Be on the new schema before producer ships   | Default for high-velocity producer teams                |
| FORWARD   | Remove optional fields                | Be able to read older messages with new code | Long-replay scenarios, consumers that out-pace producer |
| FULL      | Add optional, no required removals    | Either side can ship first                   | Cross-org integrations, regulated environments          |
| NONE      | Anything                              | Whatever the producer decided                | Never as a default                                      |

Default for an enterprise event bus: FULL. Default for a single team's internal stream: BACKWARD with an explicit `v2` channel rule for breaking changes.

## CI compatibility gates

Confluent Schema Registry:

```bash
confluent schema-registry schema check \
  --subject orders-placed-value \
  --schema schemas/orders.placed.v1.avsc \
  --type AVRO
```

AWS Glue Schema Registry:

```bash
aws glue check-schema-version-validity \
  --data-format AVRO \
  --schema-definition file://schemas/orders.placed.v1.avsc
```

Make target that fails the build:

```makefile
.PHONY: schema-check
schema-check:
	@for schema in schemas/*.avsc; do \
		confluent schema-registry schema check \
			--subject $$(basename $$schema .avsc)-value \
			--schema $$schema --type AVRO || exit 1; \
	done
```

Run on every PR. Block merges that fail.

## Anti-patterns

- Removing a field "no one is using" without auditing consumers. Lag-1 consumers and replay jobs frequently invalidate this assumption.
- Renaming with a regex find-replace across producer and consumer in one PR. Even if all consumers ship together, in-flight messages between the producer and consumer keep the old name.
- Relying on type coercion to add `int -> long`. JSON tolerates it; Avro and Protobuf depend on registry config; consumers in other languages may not.
- Treating "we will add the new field as optional and remove the old one in the next release" as a single release. That is two breaking changes pretending to be one.
- Skipping the audit table because the team is small. Even one consumer not on the migration plan is a cutover incident.

## References

- Confluent Schema Registry compatibility: https://docs.confluent.io/platform/current/schema-registry/avro.html
- Apache Avro schema resolution: https://avro.apache.org/docs/1.11.1/specification/#schema-resolution
- Protobuf field-number reuse: https://protobuf.dev/programming-guides/proto3/#updating
- AWS Glue Schema Registry compatibility: https://docs.aws.amazon.com/glue/latest/dg/schema-registry.html
