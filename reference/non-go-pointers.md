# Non-Go Pointers

Use this when the project is in a non-Go language. The patterns are identical; only the libraries differ. This file lists *options* per language ecosystem - it does not prescribe which to use. The canonical Go examples in `reference/go-examples.md` map to a different stack here; pick libraries that fit your team's existing investments.

## Java

Libraries you might consider:

Idempotent Receiver. Put the dedup check in the listener, before the business call. Common Java options for Kafka consumers include Spring Kafka, Spring Cloud Stream, and the official Apache Kafka client; for inbox persistence, ORMs such as Spring Data JPA / Hibernate / jOOQ all work, with Flyway or Liquibase for the migration. The pattern is: insert into an `inbox` table with a unique constraint on `(consumer_name, event_source, event_id)` and let the duplicate-key exception short-circuit the call.

Outbox approach. Spring Modulith ships an outbox abstraction (`@ApplicationModuleListener`) that writes the event in the same transaction as the domain change; Spring Cloud Stream also offers an outbox binder for non-CDC paths. For CDC-driven publishing, the Debezium Outbox Event Router consumes the outbox table and publishes to topics. Pick based on your team's existing stack.

Consumer endpoint. Common annotations: `@KafkaListener` (Spring Kafka), `@RabbitListener` (Spring AMQP), `@SqsListener` (Spring Cloud AWS), or hand-written consumer loops with the official Apache Kafka client.

Process Manager / saga. Options include the Temporal Java SDK, Camunda 8 Java client (for BPMN-modeled processes), and Axon Framework's saga support. Avoid hand-rolled saga state machines on top of Spring's transaction manager - they fail in subtle ways across restarts.

Minimal consumer skeleton (uses Spring Kafka for illustration; the same pattern works with Spring Cloud Stream or the official Apache Kafka client):

```java
@KafkaListener(topics = "orders.placed.v1", groupId = "inventory-consumer")
@Transactional
public void onOrderPlaced(ConsumerRecord<String, OrderPlaced> record) {
    var headers = TraceContextHeaders.from(record.headers());
    // Pattern: Idempotent Receiver - dedupe by CloudEvents id, not Kafka partition key.
    String eventId = new String(record.headers().lastHeader("ce_id").value());
    if (!inbox.markIfAbsent("inventory-consumer", record.topic(), eventId)) {
        return; // duplicate; Pattern: Idempotent Receiver
    }
    inventory.reserve(record.value().orderId());
}
```

## TypeScript / Node

Libraries you might consider:

Idempotent Receiver. Put the dedup in a guard, interceptor, or middleware that wraps the message handler. Common ORMs include Prisma, TypeORM, and Drizzle - all support `INSERT ... ON CONFLICT DO NOTHING` patterns against a unique-constrained inbox table. Frameworks such as NestJS, Fastify, or hand-rolled Node services all accommodate the same pattern; `nestjs-cls` (or the equivalent in your framework) helps with request-scoped state.

Outbox approach. Write a transactional outbox table inside the same DB transaction as the domain write (e.g., `prisma.$transaction(...)`, TypeORM `QueryRunner`, or Drizzle's transaction API), then have a relay worker or Debezium publish the rows. Avoid `await producer.send(...)` after `await tx.commit()` - that is the dual-write the outbox exists to prevent.

Consumer endpoint. Common Kafka clients in Node include KafkaJS, `@confluentinc/kafka-javascript`, and `node-rdkafka`. NestJS users can use `@MessagePattern` for supported transports; for SQS, options include `@ssut/nestjs-sqs` or the AWS SDK directly.

Process Manager / saga. Options include the Temporal TypeScript SDK, `nestjs-saga` (in-process orchestration only - does not survive restarts), and AWS Step Functions called from your service. Pick based on durability requirements.

Minimal consumer skeleton (uses NestJS + KafkaJS for illustration; the same pattern works with Fastify + `@confluentinc/kafka-javascript` or any equivalent combination):

```typescript
@Controller()
export class OrderConsumer {
  @MessagePattern('orders.placed.v1')
  async onOrderPlaced(@Payload() event: OrderPlaced, @Ctx() ctx: KafkaContext) {
    const inserted = await this.inbox.markIfAbsent('inventory-consumer', ctx.getTopic(), event.id);
    if (!inserted) return; // Pattern: Idempotent Receiver
    await this.inventory.reserve(event.orderId);
  }
}
```

## Python

Libraries you might consider:

Idempotent Receiver. Put the dedup in the consumer coroutine before the business call. Common Python ORMs (SQLAlchemy 2.x, Tortoise, Django ORM, Piccolo) all support an inbox table with a unique constraint and an `INSERT ... ON CONFLICT DO NOTHING` (or equivalent) pattern; pair with Alembic, Django migrations, or your team's chosen migration tool.

Outbox approach. A hand-rolled outbox table written via your ORM in the same DB transaction as the domain change is the most common shape. Open-source helpers such as `transactional-outbox` and `dddpy` examples exist - they are thin and worth reading rather than necessarily depending on. For Kafka, run a relay worker on whichever Kafka client your team prefers (e.g., `aiokafka`, `confluent-kafka-python`, `kafka-python`).

Consumer endpoint. Common Python Kafka clients include `aiokafka` (asyncio-native), `confluent-kafka-python` (broader feature surface, including transactions), and `kafka-python`. For SQS, `aioboto3` (async) or `boto3` (sync) with long-polling are typical. Frameworks such as FastAPI, Django, or hand-rolled async services all accommodate the same pattern.

Process Manager / saga. Options include the Temporal Python SDK, Camunda 8's Python client, AWS Step Functions called from your service, and (for narrow cases) `Faust` for stream-processing pipelines. Avoid building a saga around Celery - Celery's retry semantics are not the same as a workflow engine's deterministic replay.

Minimal consumer skeleton (uses `aiokafka` + SQLAlchemy for illustration; the same pattern works with `confluent-kafka-python` or `kafka-python` and any ORM):

```python
async def consume() -> None:
    async with AIOKafkaConsumer("orders.placed.v1", group_id="inventory-consumer") as kc:
        async for msg in kc:
            async with session.begin():
                if not await inbox.mark_if_absent(
                    "inventory-consumer", msg.topic, msg.key.decode()
                ):
                    continue  # Pattern: Idempotent Receiver
                await inventory.reserve(msg.value["order_id"])
```

## Cross-cutting libraries

- CloudEvents SDKs exist for Java, JS, and Python. Use them for envelope serialization rather than rolling your own struct.
- OpenTelemetry has stable SDKs in all three languages; the Kafka header carrier from `reference/go-examples.md` has direct equivalents (`KafkaHeadersTextMapGetter` in Java, `propagation.extract` from `@opentelemetry/api` in TS, `inject`/`extract` in Python's OTel API).
- Schema Registry clients: `io.confluent:kafka-avro-serializer` (Java), `@kafkajs/confluent-schema-registry` (TS), `confluent-kafka[avro]` (Python).

## Language-specific anti-patterns

| Language        | Trap                                                                                              |
| --------------- | ------------------------------------------------------------------------------------------------- |
| Java / Spring   | `@Async` on a `@KafkaListener` method - the offset commits before the work runs, breaking ack-after-side-effect |
| Java / Spring   | Catching the duplicate-key exception in service code instead of letting it propagate transactional rollback |
| TypeScript      | `await producer.send()` after `await tx.commit()` - this is the dual-write the outbox prevents    |
| TypeScript      | KafkaJS `eachMessage` without `manualHeartbeat` on long handlers - the consumer drops out of the group |
| Python          | Mixing sync SQLAlchemy with `aiokafka` and not awaiting the commit before the next poll           |
| Python          | Using Celery `retry` for what is actually a saga; the retry semantics do not survive worker death |

## Mapping back to the canonical patterns

For every language above, the design checklist is the same: pattern names, dedup key, retention, DLQ owner, replay safety, redaction, schema registry. The differences are syntactic. When in doubt, write the design as if it were Go (using `reference/go-examples.md`), then translate to the host language and substitute libraries.

These pointers exist so the agent can stay grounded in non-Go repos. Production code in those languages still needs to satisfy the 8-question reliability checklist, the distributed-systems checklist, and the patterns in `reference/catalog.md`.
