# Integration Pattern Catalog

A one-screen entry per pattern: **intent** (what it solves), **when to use**, **when not to**, and **modern tool**.

Modern defaults used by this skill: CloudEvents for envelopes, AsyncAPI for event API documentation, Schema Registry for compatibility gates, OpenTelemetry for trace context, Outbox + CDC for DB-write-and-publish consistency, and Go for generated code samples unless the repository indicates another language.

---

## 1. Integration Styles (4)

### File Transfer

**Intent.** Producer drops a file in a known location; consumer picks it up later.
**Use when.** Cross-org batch ingest, archival, partner feeds. Latency tolerable in minutes / hours.
**Avoid when.** Sub-minute latency or transactional consistency required.
**Modern.** S3 + EventBridge / GCS notifications, SFTP partner feeds, Iceberg / Delta tables, dbt jobs.

### Shared Database

**Intent.** Multiple apps read and write the same database.
**Use when.** Analytics / OLAP hubs (Snowflake, BigQuery), single-team monoliths.
**Avoid when.** OLTP across services - couples schemas; the moment two teams own one schema, both teams own none.
**Modern.** Data warehouse hubs, lakehouse architectures, internal `analytics.*` schemas.

### Remote Procedure Invocation

**Intent.** One app calls a function on another over the network.
**Use when.** Synchronous reads where caller can usefully fail when callee fails.
**Avoid when.** Multi-step writes; broadcast; slow callees; flaky partners.
**Modern.** REST, gRPC, GraphQL federation, tRPC, OpenAPI clients.

### Messaging

**Intent.** Apps exchange small, well-typed packets through a broker.
**Use when.** Async writes; fan-out; spike absorption; multi-consumer events.
**Avoid when.** Genuinely synchronous reads with a single consumer (use RPC).
**Modern.** Apache Kafka / Redpanda, RabbitMQ, AWS SQS / SNS / EventBridge, GCP Pub/Sub, Azure Service Bus / Event Grid, NATS JetStream, Redis Streams, Apache Pulsar.

---

## 2. Messaging System root patterns (6)

### Message Channel

**Intent.** A logical pipe connecting producers and consumers with a named contract.
**Modern.** Kafka topic, RabbitMQ exchange/queue, SQS queue, SNS topic, EventBridge bus, Pub/Sub topic, NATS subject, Redis stream, Pulsar topic.

### Message

**Intent.** A self-contained packet with a header (id, timestamp, type, correlation id) and a body (payload).
**Modern.** Avro / Protobuf / JSON Schema records, CloudEvents envelope, Kafka `ProducerRecord`, AsyncAPI message definition.

### Pipes and Filters

**Intent.** Each step is a single-purpose component (filter); channels (pipes) connect them.
**Modern.** Kafka Streams topology, Apache Flink job, Camel route, Logstash pipeline.

### Message Router

**Intent.** A filter whose only job is to forward each message to one of several outbound channels.
**Modern.** Camel `choice()`, Spring Integration `@Router`, EventBridge rule, Dapr Pub/Sub topic routing.

### Message Translator

**Intent.** Convert message format while preserving intent (the integration anti-corruption layer).
**Modern.** Schema Registry transforms, ksqlDB `SELECT`, gRPC interceptors, Camel marshallers.

### Message Endpoint

**Intent.** The application-side adapter where messaging meets domain code.
**Modern.** Spring `@KafkaListener`, AWS Lambda event source mapping, Camel consumer, NestJS `@MessagePattern`.

---

## 3. Messaging Channels (9)

### Point-to-Point Channel

**Intent.** Exactly one consumer handles each message.
**Use when.** 1-of-N delivery; competing consumers should not duplicate work.
**Modern.** RabbitMQ classic queue, AWS SQS, Service Bus queue, Kafka topic + consumer group.

### Publish-Subscribe Channel

**Intent.** Many consumers each receive their own copy of every message.
**Use when.** Producer doesn't know its consumers; fan-out by topic.
**Modern.** Kafka topic + multiple consumer groups, AWS SNS, GCP Pub/Sub, RabbitMQ fanout exchange, NATS subjects.

### Datatype Channel

**Intent.** One channel per logical message type. Consumers subscribe to what they understand.
**Use when.** Multiple event types exist (almost always).
**Modern.** Topics like `orders.placed.v1`, `orders.cancelled.v1`; AsyncAPI per channel; Schema Registry-enforced subjects.

### Invalid Message Channel

**Intent.** Forward malformed messages to a dedicated channel for inspection.
**Modern.** Spring Cloud Stream `errorChannel`; Camel `onException`; Kafka error handler deserializer; Lambda destination on failure.

### Dead Letter Channel

**Intent.** Messages exhausted of retries (or expired) go to a DLQ for manual handling.
**Use when.** Always. Without one, failures hide.
**Modern.** SQS DLQ, RabbitMQ `x-dead-letter-exchange`, Kafka DLT (`DeadLetterPublishingRecoverer`), Pub/Sub dead-letter topic.

### Guaranteed Delivery

**Intent.** Persist messages durably before ack; deliver only after consumer ack.
**Modern.** Kafka `acks=all` + RF>=3, RabbitMQ persistent + publisher confirms, SQS at-least-once, Outbox + CDC.

### Channel Adapter

**Intent.** Bolt onto an existing app's native interface (DB, REST, file, FTP, mainframe) and bridge to messaging.
**Modern.** Kafka Connect (JDBC, S3, Debezium), Camel components, AWS DMS, Apicurio Registry connectors.

### Messaging Bridge

**Intent.** Transfer messages between two messaging systems (legacy IBM MQ to Kafka).
**Modern.** Kafka MirrorMaker 2, Confluent/Redpanda replication tools, RabbitMQ Federation, Camel JMS-Kafka, EventBridge cross-account rules.

### Message Bus

**Intent.** A shared backbone with a common message infrastructure and a canonical message model.
**Modern.** Kafka + Schema Registry + AsyncAPI catalog, EventBridge default bus, Solace event mesh, Dapr pub/sub.

---

## 4. Message Construction (8)

### Command Message

**Intent.** Producer wants the receiver to do something (verb + arguments).
**Modern.** Kafka `commands.payments.v1`, SQS jobs queue, NATS request/reply, Temporal Activity command, Sidekiq / BullMQ / Celery tasks.

### Document Message

**Intent.** Producer transfers data; receiver decides what to do.
**Modern.** Avro / Protobuf records on Kafka, S3 events with object payloads, GraphQL subscription results.

### Event Message

**Intent.** Producer announces a fact (past tense: `OrderPlaced`, `PaymentSucceeded`).
**Modern.** CloudEvents on Kafka / EventBridge / Pub/Sub / NATS, Stripe-style webhooks, audit logs, DDD domain events.

### Request-Reply

**Intent.** Two channels (request + reply) tied by a Correlation ID for synchronous-over-async calls.
**Modern.** RabbitMQ RPC pattern, Kafka `ReplyingKafkaTemplate`, gRPC, NATS request/reply.

### Return Address

**Intent.** Producer puts a Return Address in the request header; receiver replies there.
**Modern.** `replyTo` in JMS / RabbitMQ properties; `reply-to` CloudEvents extension; gRPC stream metadata.

### Correlation Identifier

**Intent.** Unique id on request, echoed on reply; lets the requestor match a reply to its original request.
**Modern.** `X-Correlation-Id` header, CloudEvents `correlationid` extension, OpenTelemetry trace ids, Kafka header `correlation_id`.

### Message Sequence

**Intent.** Each part carries `{sequenceNumber, sequenceSize, sequenceId}`; receiver reassembles.
**Modern.** Multipart S3 uploads, Kafka headers + partition order, Avro union envelopes, Stripe page tokens.

### Message Expiration

**Intent.** TTL header. Channels and consumers honor it; expired messages route to DLQ or drop.
**Modern.** Kafka topic retention + TTL/expiry headers, RabbitMQ `x-message-ttl`, SQS message timer, CloudEvents `expirytime`.

### Format Indicator

**Intent.** Header / version / schema id so receivers route or translate based on it.
**Modern.** Kafka header `contentType`, Schema Registry schema id, CloudEvents `specversion` and `datacontenttype`, OpenAPI / AsyncAPI version pins.

---

## 5. Message Routing (11)

### Content-Based Router

**Intent.** Single input; router examines content and forwards to one of N outputs.
**Modern.** Camel `choice()`, Spring Integration `@Router`, EventBridge content-based rules, ksqlDB `WHERE`.

### Message Filter

**Intent.** Drop anything that fails a predicate.
**Modern.** Kafka Streams `filter()`, AWS SNS subscription filter policies, RabbitMQ headers exchange, Pub/Sub filters.

### Dynamic Router

**Intent.** Routing rules change at runtime (subscribers register/unregister; control channel updates).
**Modern.** Camel dynamic routes, Dapr pub/sub subscription updates, feature-flagged EventBridge rules, etcd-backed registries.

### Recipient List

**Intent.** Compute a per-message list of recipients; publish a copy to each.
**Modern.** SNS topic + filter policies, EventBridge multi-target rule, Camel `recipientList()`, Mailgun batch send.

### Splitter

**Intent.** Break a composite message into N child messages processed independently.
**Modern.** Kafka Streams `flatMap()`, Spring Batch, Camel `split()`, Step Functions `Map`, Flink `flatMap()`.

### Aggregator

**Intent.** Stateful filter that correlates, completes, and publishes a composite of N related messages.
**Modern.** Kafka Streams `aggregate()` + window, Flink session window, Camel `aggregate()`, ksqlDB `GROUP BY ... WINDOW`.

### Resequencer

**Intent.** Buffer messages; emit them in order based on a sequence number; flush on timeout.
**Modern.** Flink event-time + watermarks, Kafka Streams windowed reordering, Kinesis sequence numbers, Camel `resequence()`.

### Composed Message Processor

**Intent.** A meta-filter that internally splits, processes, and aggregates (encapsulates a sub-pipeline).
**Modern.** Kafka Streams sub-topology, Flink job graph, Camel route as endpoint, Step Functions parallel state.

### Scatter-Gather

**Intent.** Send the question to all (scatter); gather and aggregate the responses.
**Modern.** GraphQL federation, parallel Kafka Streams branches, Step Functions `Parallel`, Camel multicast + aggregate.

### Routing Slip

**Intent.** Compute an ordered list of channels (the "slip") at the start; each step pops the next stop.
**Modern.** Camel `routingSlip()`, Step Functions dynamic ordering, Temporal workflows, Camunda, Saga choreography frameworks.

### Process Manager

**Intent.** Central component owns a multi-step state machine; emits commands and consumes events.
**Use when.** Long-running workflows, sagas, anything with retries / timeouts / compensations.
**Modern.** **Temporal**, AWS Step Functions, Azure Durable Functions, Camunda 8, Netflix Conductor, Spring StateMachine.

### Message Broker

**Intent.** Central component receives all messages and routes/transforms them; apps know only the broker.
**Modern.** Kafka / Redpanda cluster, RabbitMQ, AWS EventBridge, GCP Pub/Sub, Solace, NATS JetStream, Pulsar.

---

## 6. Message Transformation (7)

### Message Translator

**Intent.** Filter that converts one schema/format to another (XML to JSON, v1 to v2, EDI to Avro).
**Modern.** Kafka Streams `mapValues`, Flink, Schema Registry conversions, GraphQL resolvers, Camel marshalers, Lambda transformers, JSON Patch / JSONata.

### Envelope Wrapper

**Intent.** Wrap payload with envelope on send; strip on receive.
**Modern.** **CloudEvents** envelope (`id`, `source`, `type`, `subject`, `time`, `specversion`, `datacontenttype`, `data`), Kafka headers + payload, SNS message attributes.

### Content Enricher

**Intent.** Insert an enricher that joins external data (DB, cache, API) into the message.
**Modern.** Kafka Streams `KStream.leftJoin(KTable)`, Flink async I/O, Camel `enrich()`, GraphQL nested resolvers.

### Content Filter

**Intent.** Strip / project to just what the receiver needs; protect sensitive fields.
**Modern.** Kafka Streams projection, GraphQL field selection, Avro projection, OPA / column masking, Glue mask transforms.

### Claim Check

**Intent.** Persist large payload to a store; replace it in the message with a token (claim check).
**Modern.** Upload to S3 / GCS / Azure Blob, send `{uri, etag, sha256, size}` through the broker. SNS Large Payload Support, Pub/Sub + GCS.

### Normalizer

**Intent.** A normalizer routes by source-format, then translates each variant to a common form.
**Modern.** Camel content-based router + per-source translators, Schema Registry SMTs, Logstash filter pipelines.

### Canonical Data Model

**Intent.** One neutral schema. Each app translates between its own format and the canonical one. M+N translators instead of MxN.
**Modern.** Schema Registry + canonical Avro / Protobuf / JSON Schema, AsyncAPI specs, CloudEvents type registry, FHIR / HL7, ISO 20022.

---

## 7. Messaging Endpoints (11)

### Messaging Gateway

**Intent.** Wrap broker API in a domain-shaped gateway interface; tests mock the interface.
**Modern.** Go broker interfaces around Kafka/SQS/Pub/Sub clients, Spring `@MessagingGateway`, NestJS `ClientProxy`, Lambda handler functions, MassTransit / Wolverine endpoints.

### Messaging Mapper

**Intent.** Separate mapper class converts between domain objects and message payloads.
**Modern.** Go typed mappers and generated Protobuf/Avro structs, Jackson / kotlinx.serialization, MapStruct, AutoMapper, Schema Registry serializers.

### Transactional Client

**Intent.** Update local DB and ack message together - or roll back together.
**Modern.** **Transactional Outbox** + Debezium CDC + Kafka, Kafka transactions/EOS for Kafka-contained read-process-write, DynamoDB Streams + Lambda. _Avoid distributed 2PC._

### Polling Consumer

**Intent.** Consumer asks the channel for messages on its own schedule.
**Use when.** Need rate control, downstream limits.
**Modern.** Kafka `consumer.poll()`, SQS long-polling, scheduled Lambda, cron + `SELECT FOR UPDATE`.

### Event-Driven Consumer

**Intent.** Broker pushes the message into the consumer's callback / handler.
**Modern.** RabbitMQ `basic.consume`, AWS Lambda triggers, Spring `@KafkaListener`, NestJS `@MessagePattern`.

### Competing Consumers

**Intent.** Multiple consumer instances pull from the same queue; broker hands each message to exactly one.
**Modern.** Kafka consumer group with N members on N partitions, SQS multiple receivers, RabbitMQ multiple consumers, Lambda concurrency.

### Message Dispatcher

**Intent.** A dispatcher reads the channel and hands each message to a per-type performer (handler).
**Modern.** Spring `@KafkaHandler` per-type methods, NestJS per-type `@MessagePattern`, NATS subject hierarchies.

### Selective Consumer

**Intent.** Consumer applies a selector / filter when subscribing - only relevant messages arrive.
**Modern.** JMS message selectors, RabbitMQ headers exchange, SNS subscription filter policies, Pub/Sub subscription filters.

### Durable Subscriber

**Intent.** Broker stores messages for the named subscriber until acknowledged.
**Modern.** Kafka consumer offsets, MQTT persistent sessions, SNS to SQS subscription, Pub/Sub durable subscription.

### Idempotent Receiver

**Intent.** Same message twice means the same effect once. Dedupe by message id; design state changes to be naturally idempotent.
**Use when.** Always with at-least-once delivery (i.e., almost always).
**Modern.** Redis `SETNX seen:{id} EX 86400`, DB unique constraint on idempotency key, Kafka EOS with `read_committed`, Stripe `Idempotency-Key`.

### Service Activator

**Intent.** An activator subscribes to a channel and invokes an existing non-messaging service per message.
**Modern.** Spring `@ServiceActivator`, AWS API Gateway + Lambda + SQS, Knative Eventing trigger, Camel `to("bean:...")`.

---

## 8. System Management (8)

### Control Bus

**Intent.** Separate channel carrying control messages (start, stop, log-level, throttle, drain).
**Modern.** Spring Cloud Bus + RabbitMQ, Kubernetes ConfigMap reloads, LaunchDarkly / Unleash, Dapr configuration API, Consul KV.

### Detour

**Intent.** A switch (toggled via Control Bus) sends messages through an extra hop, then back.
**Modern.** Camel toggle endpoint with feature flag, EventBridge rule to debug consumer, shadow traffic with Istio mirroring.

### Wire Tap

**Intent.** Copy every message to a side channel for inspection - non-destructive.
**Modern.** Kafka MirrorMaker into audit topic, Kafka Connect to S3 / OpenSearch, Camel `wireTap()`, EventBridge archive, eBPF tracing.

### Message History

**Intent.** Each component appends its name (and timestamp) to a header on every message; the trail follows the message.
**Modern.** **OpenTelemetry** trace context (W3C Trace Context), Jaeger / Tempo / Datadog APM, Micrometer Tracing, AWS X-Ray.

### Message Store

**Intent.** A wire-tap into a long-term store keeps every message for later querying / replay.
**Modern.** Kafka log compaction + topic retention, Kafka Connect to S3 / BigQuery / Snowflake, EventBridge archive + replay, Kinesis Firehose.

### Smart Proxy

**Intent.** A proxy in front of a service does logging, retry, throttling, fan-out - all without modifying the service.
**Modern.** Envoy / Istio sidecars, AWS API Gateway, sidecar consumers in K8s, Dapr middleware, RabbitMQ shovel + transform.

### Test Message

**Intent.** Send a clearly-marked test message; downstream tags it as test and routes appropriately.
**Modern.** Synthetic monitoring with marked headers, Datadog Synthetics, Lambda canary tests, contract testing in CI.

### Channel Purger

**Intent.** Operator tool drains / discards specific messages on the channel after a flood or stale data.
**Modern.** Kafka `kafka-delete-records` + topic compaction, RabbitMQ purge queue, SQS `PurgeQueue`, console actions on Pub/Sub.

---

## Summary

- **Integration Styles** (4) - pick the right shape before reaching for a broker.
- **Messaging Channels** (9) - topology: how messages travel, with what guarantees.
- **Message Construction** (8) - individual message intent, identity, lifetime, and format.
- **Message Routing** (11) - split, join, route, orchestrate.
- **Message Transformation** (7) - translate, enrich, filter, canonicalize.
- **Messaging Endpoints** (11) - application-side adapters: how producers and consumers attach.
- **System Management** (8) - operate, observe, replay, and recover the messaging system.

Memorize the categories, then look up the specific pattern here when the problem gets concrete.
