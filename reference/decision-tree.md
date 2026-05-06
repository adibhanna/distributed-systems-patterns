# Decision Tree - Problem To Pattern

Use this as the first stop when designing or reviewing an integration. After selecting patterns, run `reference/checklist.md`.

## "I need cross-service writes."

1. **Transactional Client via Outbox + CDC** - atomic local DB write plus message record.
2. **Event Message** - publish an immutable fact after the local transaction commits.
3. **Datatype Channel** - one event type per semantic channel.
4. **Idempotent Receiver** - every mutating consumer dedupes.
5. **Dead Letter Channel** + bounded retry - failures are visible and recoverable.
6. **Process Manager** if multiple downstream writes must converge on one business outcome.

Tools: Postgres/MySQL outbox, Debezium, Kafka/Redpanda, Schema Registry, CloudEvents, Temporal.

Avoid: `db.save(); broker.publish();`.

## "I need to fan out an event to many services."

1. **Event Message** - past-tense fact such as `OrderPlaced`.
2. **Publish-Subscribe Channel** - each consumer gets its own copy.
3. **Datatype Channel** - one logical event type per channel.
4. **Durable Subscriber** - offline consumers retain their place.
5. **Idempotent Receiver** - each subscriber handles duplicate delivery.

Tools: Kafka topic + multiple consumer groups, SNS -> SQS, Pub/Sub, EventBridge.

## "I need request-reply over async messaging."

1. **Request-Reply** - request and response channels.
2. **Return Address** - reply channel in header.
3. **Correlation Identifier** - request id echoed in reply.
4. **Message Expiration** - deadline after which the reply is useless.
5. **Invalid Message Channel** - malformed replies do not block the requestor.

Tools: NATS request/reply, RabbitMQ RPC, Kafka reply topic.

Caveat: if the caller needs an immediate answer and there is one stable callee, use REST/gRPC instead.

## "I need to scale consumers."

1. **Competing Consumers** - N instances share one work channel.
2. **Polling Consumer** for rate control, or **Event-Driven Consumer** for push/callback style.
3. **Idempotent Receiver** - duplicates are normal under at-least-once delivery.
4. **Backpressure** - bounded prefetch, bounded workers, downstream timeouts.
5. **Selective Consumer** only if workers specialize.

Tools: Kafka consumer groups, SQS multiple receivers, RabbitMQ consumers, Pub/Sub subscribers, Lambda concurrency.

## "I need a long-running business process."

1. **Process Manager** - explicit durable state machine.
2. **Command Message** - ask services to perform actions.
3. **Event Message** - receive immutable results.
4. **Compensation** - undo each completed step where business rules require it.
5. **Idempotent Receiver** - every activity/step can be retried.
6. **Message Store** - replay and audit.

Tools: Temporal, AWS Step Functions, Azure Durable Functions, Camunda 8.

Avoid pure choreography when the state machine must be understood, queried, cancelled, or compensated.

## "I need to process a composite message in parallel."

1. **Splitter** - create child messages.
2. **Message Sequence** - carry sequence id, number, and size.
3. **Competing Consumers** - process children in parallel.
4. **Aggregator** - join children by correlation id.
5. **Resequencer** if downstream output order matters.
6. **Message Expiration** - bound the wait for missing children.

Tools: Kafka Streams, Flink, Step Functions Map, Camel split/aggregate.

## "I need to query several services and combine answers."

1. **Scatter-Gather** - ask multiple recipients.
2. **Recipient List** - compute recipients if dynamic.
3. **Aggregator** - combine all, quorum, first-success, or threshold responses.
4. **Message Expiration** - deadline for late responses.
5. **Correlation Identifier** - tie replies to request.

Tools: Step Functions Parallel, GraphQL federation, Camel multicast + aggregate, Temporal child workflows.

## "I need to convert formats or versions."

1. **Format Indicator** - schema id/version/content type in header or envelope.
2. **Message Translator** - convert source to target format.
3. **Normalizer** if multiple source formats mean the same concept.
4. **Canonical Data Model** if many producers/consumers otherwise cause M x N translators.

Tools: Schema Registry, Kafka Streams/Flink, ksqlDB, Camel, JSONata, Protobuf/Avro evolution.

Keep business rules out of translators.

## "I need to design a new event contract."

1. **Event Message** for facts, **Command Message** for requested action.
2. **Envelope Wrapper** - CloudEvents.
3. **Datatype Channel** - semantic channel name and version.
4. **Format Indicator** - schema id/content type/spec version.
5. **Canonical Data Model** where multiple systems share the contract.
6. **Message History** - trace context, correlation, causation.

Tools: AsyncAPI 3.x, CloudEvents 1.0, Schema Registry, Avro/Protobuf/JSON Schema.

Start from `reference/message-contract-template.md`.

## "I need to implement this in Go."

1. **Messaging Gateway** - small interface around broker operations.
2. **Messaging Mapper** - typed domain <-> envelope/schema conversion.
3. **Transactional Outbox** for producers.
4. **Idempotent Receiver** for consumers.
5. **Dead Letter Channel** and bounded retry.
6. **Message History** using OpenTelemetry header carrier.

Tools: `cloudevents/sdk-go`, `kafka-go` or repo-standard Kafka client, `pgx`, `go-redis`, `log/slog`, OpenTelemetry Go.

Use `reference/go-examples.md`.

## "I need to migrate from a legacy broker to Kafka."

1. **Messaging Bridge** - copy from old broker to new.
2. **Datatype Channel** - design new topics intentionally.
3. **Message Translator** if envelope/schema changes.
4. **Wire Tap** - monitor without disturbing traffic.
5. **Idempotent Receiver** at the destination.
6. Decommission consumer-by-consumer; producer last.

Tools: Kafka Connect, MirrorMaker 2, Camel JMS-Kafka, RabbitMQ Federation, Confluent/Redpanda tools.

## "I need to handle third-party webhooks."

1. **Channel Adapter** - HTTP endpoint validates and converts webhook to internal message.
2. **Idempotent Receiver** - dedupe by provider delivery id.
3. **Message Store** - keep raw signed message for audit/replay where allowed.
4. **Dead Letter Channel** - bad signatures, malformed payloads, permanent processing failures.
5. **Wire Tap** - audit stream.
6. **Smart Proxy** - rate limit, auth, signature verification.

Tools: API Gateway/Cloudflare Workers/Lambda -> SQS/Kafka, DynamoDB/Redis dedup, provider signature verification.

## "I need to inspect or audit messages without changing flow."

1. **Wire Tap** - copy every message to a side channel.
2. **Message Store** - durable searchable store.
3. **Message History** - trace context across hops.
4. **Smart Proxy** if auth/throttling/logging must be centralized.

Tools: Kafka Connect to S3/OpenSearch/Snowflake, EventBridge Archive, OpenTelemetry Collector.

## "I need exactly-once semantics."

Treat this as a design review, not a checkbox.

1. **Idempotent Receiver** - effectively-once business outcome.
2. **Transactional Client** - commit offsets with output where supported.
3. **Kafka transactions/EOS** only when read-process-write stays inside Kafka-compatible transactional boundaries.
4. **Process Manager** when business semantics span services.

Avoid distributed 2PC/XA across services. For external side effects, exactly-once usually means at-least-once delivery plus idempotent side effects.

## "Producer is too fast for consumer."

1. **Competing Consumers** - add workers up to the partition/concurrency cap.
2. **Backpressure** - bounded prefetch/poll and worker pools.
3. **Message Expiration** - drop stale work rather than preserving useless backlog.
4. **Detour** - slower path or batch lane for non-urgent work.
5. **Channel Purger** only as an emergency runbook step.

Never fix sustained overload with unbounded buffers.

## "I need cross-region durability."

1. **Messaging Bridge** - replicate between regions.
2. **Idempotent Receiver** - duplicates after failover are expected.
3. **Message Store** - replay source of truth.
4. **Geo-aware partitioning** - preserve per-key locality where possible.
5. Decide active-active vs active-passive before implementation.

Tools: MirrorMaker 2/Replicator, EventBridge global endpoints where suitable, cloud-native DR, object-store replay.

## "I need read-after-write consistency."

Messaging is async by default.

1. Serve the read from the writer's database if the writer owns the truth.
2. Or use RPC for that specific read path.
3. Or expose workflow status from a **Process Manager** and let the user wait/poll.
4. Or use **Aggregator** when the user needs a combined async result.

If the path cannot tolerate eventual consistency, do not pretend messaging will make it synchronous.

## "I need to operate this in production."

1. **Control Bus** - runtime controls for drain, throttle, log level, feature flags.
2. **Wire Tap** + **Message Store** - audit and replay.
3. **Message History** - OpenTelemetry.
4. **Test Message** - synthetic monitoring.
5. **Channel Purger** - emergency operations, not regular control flow.
6. Dashboards and runbooks for lag/age, DLQ, retry rate, end-to-end latency, broker health.

Use `reference/production-guide.md`.

## "I need to implement this on AWS."

1. Name the cloud-neutral pattern first.
2. Map it to the AWS service: SQS for work queues, SNS/EventBridge for fan-out/routing, Kinesis/MSK for streams, DynamoDB Streams for CDC, Step Functions for Process Manager, S3 for Claim Check.
3. Apply AWS-specific reliability checks: visibility timeout, partial batch response, DLQ/redrive, archive/replay, shard/message-group ordering, IAM, and CloudWatch/X-Ray/OpenTelemetry.
4. Keep contracts portable with CloudEvents/AsyncAPI/schema files even when EventBridge/SNS/SQS is the transport.

Use `reference/aws-service-mapping.md`.

## "This is more distributed systems than messaging."

1. **Bounded Context + Database Per Service** - define ownership before transport.
2. **Consistency Model** - name the business invariant and allowed staleness.
3. **Circuit Breaker + Bulkhead + Timeout** - prevent cascading failure.
4. **Backpressure + Load Shedding + Rate Limiting** - survive overload.
5. **Sharding/Partitioning** if the data or traffic cannot scale as one unit.
6. **Cache-Aside / Read Replica / CQRS Read Model** if read latency or load dominates.
7. **Progressive Delivery** for safe release.

Tools: Kubernetes HPA/KEDA, Envoy/Istio/Linkerd, Dapr resiliency, Redis/CDN, OpenTelemetry, Prometheus/Grafana, Argo Rollouts/Flagger.

Use `reference/distributed-systems-guide.md`.

## "I need an architecture document / RFC / ADR."

1. Pick the document type: Architecture Overview, RFC, ADR, Implementation Plan, Migration Plan, Production Readiness Review, or Event Contract Spec.
2. Name the integration and distributed-systems patterns.
3. Define goals/non-goals, requirements, SLOs, ownership, and constraints.
4. Document proposed architecture, flows, data/contracts, consistency, scale, resilience, observability, security, and operations.
5. Compare alternatives and trade-offs.
6. Add rollout, rollback, migration, testing, verification, risks, and open questions.

Use `reference/architecture-documentation.md`.

## "I need a production runbook."

1. Identify incident type: DLQ, consumer lag, stuck workflow, replay/backfill, schema rollback, or region failover.
2. Name owner, dashboard, safety warnings, stop criteria, and audit requirements.
3. Include step-by-step triage, mitigation, verification, and post-incident actions.

Use `reference/operational-runbooks.md`.

## "I need to know how this fails."

1. Load the failure mode catalog.
2. Map likely failures to this design.
3. Add mitigation patterns and tests for each high-impact failure.

Use `reference/failure-modes.md`.

## "I need tests for this architecture."

1. Map tests to patterns: outbox, idempotent receiver, DLQ, retry, process manager, claim check, cache, shard.
2. Include contract, integration, replay, failure, load, and operational drill tests where relevant.
3. Add CI gates for schema compatibility and Go tests.

Use `reference/testing-strategy.md`.

## "I need security/compliance review."

1. Classify data in payloads, headers, traces, logs, DLQs, replay stores.
2. Check authN/authZ, IAM/ACLs, encryption, retention, tenant isolation, and audit.
3. For webhooks, verify signatures, timestamp windows, and dedup.

Use `reference/security-compliance.md`.

## "I need to scale a service."

1. Find the bottleneck: CPU, memory, DB locks, connection pool, partition, downstream rate limit, or queue age.
2. Reduce work with caching, filtering, batching, or precomputation.
3. Add horizontal replicas if stateless.
4. Add queue-based scaling if work is asynchronous.
5. Partition/shard when one data owner cannot scale vertically.
6. Add backpressure, rate limits, and circuit breakers before raising concurrency.

Tools: Kubernetes HPA for resource/custom metrics; KEDA for event-source metrics; Envoy/Dapr for resilience; Redis/CDN/read replicas for read load.

## "I need multi-region or disaster recovery."

1. Name active-passive, active-active, or single-writer/multi-reader.
2. Define RPO, RTO, failover trigger, failback plan, and data residency.
3. Decide conflict policy before implementation.
4. Use Messaging Bridge / CDC / Message Store for event/data movement.
5. Make consumers idempotent and replay-safe across regions.
6. Test failover and failback, not only backup restore.

Use `reference/distributed-systems-guide.md`.
