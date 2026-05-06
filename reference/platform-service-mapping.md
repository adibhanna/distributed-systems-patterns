# Cloud And Platform Service Mapping

Use this when the user is not on AWS or wants a cloud-neutral comparison. For AWS-specific details, use `reference/aws-service-mapping.md`.

## Quick map

| Pattern need | AWS | GCP | Azure | Open source / self-managed |
| --- | --- | --- | --- | --- |
| Work queue | SQS | Pub/Sub subscription, Cloud Tasks | Service Bus Queue | RabbitMQ, NATS JetStream |
| Fan-out | SNS, EventBridge | Pub/Sub, Eventarc | Event Grid, Service Bus Topic | Kafka, RabbitMQ exchange, Pulsar |
| Event stream/replay | Kinesis, MSK | Pub/Sub with retention/seek, Dataflow, Managed Kafka | Event Hubs | Kafka/Redpanda/Pulsar |
| Workflow/process manager | Step Functions | Workflows, Temporal on GKE | Durable Functions, Logic Apps | Temporal, Camunda, Conductor |
| CDC/outbox | DMS, Debezium/MSK Connect, DynamoDB Streams | Datastream, Pub/Sub, Dataflow | Data Factory, Event Hubs, Change Feed | Debezium, Kafka Connect |
| Schema registry | Glue Schema Registry, EventBridge schemas | Pub/Sub schemas | Event Hubs Schema Registry | Confluent/Apicurio/Redpanda |
| Claim Check | S3 | Cloud Storage | Blob Storage | MinIO/object storage |
| Queue-based autoscaling | Lambda concurrency, KEDA on EKS | Cloud Run scaling, KEDA on GKE | Functions scaling, KEDA on AKS | Kubernetes HPA/KEDA |
| Observability | CloudWatch, X-Ray, OTel | Cloud Monitoring/Trace, OTel | Azure Monitor/App Insights, OTel | Prometheus/Grafana/Tempo/Jaeger |

## Selection guidance

- Choose managed queues for simple work distribution.
- Choose streams when replay, ordering by key, many consumer groups, or stream processing are core requirements.
- Choose workflow engines when business state, timeouts, compensation, and queryability matter.
- Choose EventBridge/Eventarc/Event Grid for cloud/SaaS routing and event bus integration.
- Choose Kafka/Redpanda/Pulsar when portability, high throughput, replay, and ecosystem matter.
- Choose RabbitMQ/NATS when low-latency commands, routing, or operational simplicity fit better than long-retention streams.

## GCP notes

- Pub/Sub is at-least-once by default; exactly-once delivery is scoped to supported pull subscriptions and regional/ack behavior. Still use idempotency for side effects.
- Ordering keys can create hot keys and blocked delivery.
- Dead-letter topics and retry policies need owner and redrive plan.
- Eventarc uses CloudEvents, which maps well to this skill's envelope guidance.
- Cloud Workflows can act as Process Manager for GCP-native flows.

## Azure notes

- Service Bus queues/topics support duplicate detection, sessions for ordering, dead-letter queues, and scheduled delivery. Duplicate detection is time-windowed and depends on application-controlled message IDs.
- Event Grid fits event routing and cloud events; configure retry/dead-letter.
- Event Hubs is the Kafka-like high-throughput stream service; use consumer groups and partition keys.
- Durable Functions fits Process Manager/Saga flows in Azure-native applications.

## Kafka/RabbitMQ/NATS/Pulsar notes

- Kafka/Redpanda: strong fit for durable streams, replay, partitions, stream processing, and many independent consumers.
- RabbitMQ: strong fit for work queues, routing, RPC-ish commands, publisher confirms, and DLX-based failure handling.
- NATS JetStream: strong fit for low-latency messaging with durable streams and simpler operations.
- Pulsar: strong fit for multi-tenant streaming, geo-replication, and separated compute/storage.

Always evaluate team experience and operational maturity, not only feature fit.
