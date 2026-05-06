# Non-Go Pointers

Use this when the target codebase is Java, TypeScript/Node, or Python, and the canonical Go examples in `reference/go-examples.md` need to be mapped to a different stack. The patterns are unchanged; only the libraries and idiomatic shapes differ.

## Java (Spring Boot)

Idempotent Receiver. Put the dedup check in the listener, before the business call. Use a Spring `@Transactional` method that inserts into an `inbox` table with a unique constraint on `(consumer_name, event_source, event_id)`; let the duplicate-key exception short-circuit the call. Libraries: Spring Data JPA, Flyway/Liquibase for the inbox migration.

Outbox approach. Spring Modulith ships an outbox abstraction (`@ApplicationModuleListener`) that writes the event in the same transaction as the domain change. For Kafka specifically, the Debezium Outbox Event Router consumes the outbox table and publishes to topics. Spring Cloud Stream Outbox is also viable for non-CDC paths.

Consumer endpoint. `@KafkaListener` for Kafka, `@RabbitListener` for RabbitMQ, `@SqsListener` (Spring Cloud AWS) for SQS.

Process Manager / saga. Temporal Java SDK is the safest default. Camunda 8 Java client works for BPMN-modeled processes. Avoid hand-rolled saga state machines on top of Spring's transaction manager — they fail in subtle ways across restarts.

Minimal consumer skeleton:

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

## TypeScript / Node (NestJS)

Idempotent Receiver. Put the dedup in a guard or interceptor that wraps the message handler; persist via the project's ORM (Prisma, TypeORM, Drizzle) using `INSERT ... ON CONFLICT DO NOTHING`. Libraries: `nestjs-cls` for request-scoped state; the ORM itself for the unique constraint.

Outbox approach. `@nestjs/cqrs` plus a transactional outbox table written via Prisma/TypeORM in the same `prisma.$transaction(...)` as the domain write. For Kafka, run a small relay worker (or Debezium) that reads the outbox and publishes. Avoid `await producer.send(...)` after `await tx.commit()` — that is the dual-write the outbox exists to prevent.

Consumer endpoint. `@MessagePattern` (NestJS microservices) for the supported transports. For Kafka, prefer KafkaJS directly with a thin NestJS module wrapper; for SQS, `@ssut/nestjs-sqs`.

Process Manager / saga. Temporal TypeScript SDK is the safest default. `nestjs-saga` works for in-process orchestration but does not survive restarts the way Temporal does.

Minimal consumer skeleton:

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

## Python (FastAPI / Async)

Idempotent Receiver. Put the dedup in the consumer coroutine before the business call. Use SQLAlchemy with `INSERT ... ON CONFLICT DO NOTHING` (Postgres) and a unique constraint on the inbox table. Libraries: SQLAlchemy 2.x, Alembic for migrations.

Outbox approach. SQLAlchemy plus a hand-rolled outbox table is the most common. The `transactional-outbox` package and `dddpy` examples exist; they are thin and worth reading rather than depending on. For Kafka, run a relay worker built on `aiokafka` or `confluent-kafka-python`.

Consumer endpoint. `aiokafka` for asyncio-native Kafka; `confluent-kafka-python` for the broader feature surface (transactions, exactly-once support). For SQS, `aioboto3` with manual long-polling.

Process Manager / saga. Temporal Python SDK is the safest default. Camunda 8 has a Python client. Avoid building a saga around Celery — Celery's retry semantics are not the same as a workflow engine's deterministic replay.

Minimal consumer skeleton:

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
