# Message Contract Template

Use this when designing a new event, command, webhook, topic, queue, or AsyncAPI contract.

## Contract checklist

- Pattern names: Event Message, Command Message, Datatype Channel, Publish-Subscribe Channel, etc.
- Channel name: semantic and versioned, for example `orders.placed.v1`.
- Owner: team, Slack/email, on-call escalation.
- Envelope: CloudEvents 1.0.
- Payload schema: Avro, Protobuf, or JSON Schema.
- Compatibility: backward required, forward preferred.
- Ordering key: business id such as `order_id`, or "none".
- Idempotency key: CloudEvents `id` unless a stronger business key is required.
- Correlation and causation: `correlationid`, `causationid`, and W3C `traceparent`.
- Retention and replay policy.
- DLQ policy and owner.
- PII/security classification.

## CloudEvents envelope

`correlationid`, `causationid`, `partitionkey`, `traceparent`, and `expirytime` are CloudEvents extensions in this skill's convention. Document them in AsyncAPI and keep names stable.

```json
{
  "specversion": "1.0",
  "id": "018f6f75-8d7d-7c07-9b93-2f2c2f2c2f2c",
  "source": "orders-service",
  "type": "com.acme.orders.placed.v1",
  "subject": "order_123",
  "time": "2026-05-06T14:30:00Z",
  "datacontenttype": "application/json",
  "correlationid": "req_abc",
  "causationid": "cmd_place_order_123",
  "partitionkey": "order_123",
  "traceparent": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
  "data": {
    "order_id": "order_123",
    "customer_id": "cust_456",
    "total_cents": 1299
  }
}
```

## AsyncAPI 3.1 starter

```yaml
asyncapi: 3.1.0
info:
  title: Orders Events
  version: 1.0.0
  description: Event API owned by the Orders team.

servers:
  production:
    host: kafka.prod.acme.internal:9092
    protocol: kafka

channels:
  ordersPlacedV1:
    address: orders.placed.v1
    description: Datatype Channel for OrderPlaced facts.
    messages:
      orderPlaced:
        $ref: "#/components/messages/OrderPlaced"

operations:
  publishOrderPlaced:
    action: send
    channel:
      $ref: "#/channels/ordersPlacedV1"
    messages:
      - $ref: "#/channels/ordersPlacedV1/messages/orderPlaced"
  receiveOrderPlaced:
    action: receive
    channel:
      $ref: "#/channels/ordersPlacedV1"
    messages:
      - $ref: "#/channels/ordersPlacedV1/messages/orderPlaced"

components:
  messages:
    OrderPlaced:
      name: OrderPlaced
      title: Order placed
      summary: Immutable fact emitted after an order is durably accepted.
      contentType: application/cloudevents+json
      traits:
        - $ref: "#/components/messageTraits/CloudEventsRequired"
      payload:
        $ref: "#/components/schemas/OrderPlacedPayload"

  messageTraits:
    CloudEventsRequired:
      headers:
        type: object
        required:
          - traceparent
        properties:
          traceparent:
            type: string
          correlationid:
            type: string
          causationid:
            type: string
          partitionkey:
            type: string

  schemas:
    OrderPlacedPayload:
      type: object
      additionalProperties: false
      required:
        - order_id
        - customer_id
        - total_cents
      properties:
        order_id:
          type: string
        customer_id:
          type: string
        total_cents:
          type: integer
          minimum: 0
```

## Versioning policy

- Patch/minor changes may add optional fields with defaults.
- Required fields, renamed fields, removed fields, or type changes require a new channel version.
- Consumers must ignore unknown optional fields.
- Producers must continue publishing `v1` until every known consumer has migrated or the deprecation window expires.
- The CI gate must run schema compatibility checks before publish code merges.

## Review prompt

```text
Use the distributed-systems-patterns skill to review this message contract.
Name the patterns, answer the 8 reliability questions, check AsyncAPI/schema compatibility,
and flag production gaps before implementation.
```
