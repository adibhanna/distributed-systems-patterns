# AWS Service Mapping

Use this when the implementation target is AWS or the user asks how distributed-systems, integration, workflow, and resilience patterns map to AWS services. Keep the skill cloud-neutral: name the pattern first, then choose the AWS realization.

## Quick map

| Pattern need              | AWS realization                                                                                        | Notes                                                                                       |
| ------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| Point-to-Point Channel    | SQS Standard/FIFO queue, Lambda event source mapping                                                   | Standard is at-least-once and best-effort order; FIFO adds message groups and dedupe window |
| Competing Consumers       | Multiple Lambda consumers, ECS/EKS workers polling SQS, KCL workers                                    | Control concurrency and visibility timeout                                                  |
| Publish-Subscribe Channel | SNS topic -> SQS queues, EventBridge bus/rules, Kinesis/MSK consumer groups                            | SNS fan-out is simple; EventBridge adds routing/archive/SaaS integration                    |
| Datatype Channel          | One SNS topic/EventBridge detail-type/Kinesis stream/MSK topic per event type where feasible           | Avoid one `events` bus rule set with unrelated payloads and no ownership                    |
| Content-Based Router      | EventBridge event patterns, SNS filter policies, EventBridge Pipes filters                             | Keep routing declarative; business logic belongs in consumers/workflows                     |
| Message Translator        | Lambda/EventBridge Pipes enrichment, Step Functions task, Managed Service for Apache Flink, MSK/Flink  | Keep schema changes explicit and tested                                                     |
| Transactional Outbox      | RDS/Aurora outbox + Debezium on MSK Connect, DynamoDB table + Streams, app-owned outbox publisher      | Avoid DB commit followed by direct publish                                                  |
| Idempotent Receiver       | DynamoDB conditional put with TTL, RDS unique index, ElastiCache Redis `SETNX`                         | Required for SQS/SNS/EventBridge/Kinesis/MSK duplicate delivery                             |
| Dead Letter Channel       | SQS DLQ/redrive, Lambda destinations/on-failure, EventBridge DLQ, SNS DLQ, Step Functions Catch path   | DLQ must have owner, alarm, and redrive runbook                                             |
| Message Store             | EventBridge Archive, Kinesis retention, S3 via Firehose/Kafka Connect, CloudWatch Logs for diagnostics | Store enough to replay and investigate, not secrets                                         |
| Process Manager           | Step Functions Standard, Temporal on ECS/EKS/EC2, AWS Managed Workflows where applicable               | Step Functions Standard is the usual AWS-native saga engine                                 |
| Message History           | OpenTelemetry trace context, AWS X-Ray, CloudWatch EMF metrics                                         | Propagate `traceparent`; do not rely only on AWS request ids                                |
| Claim Check               | S3 object + SQS/SNS/EventBridge/Kinesis message containing `{bucket,key,etag,sha256}`                  | Add lifecycle policy and access control                                                     |
| Control Bus               | EventBridge Scheduler/rules, SSM Parameter Store/AppConfig, Step Functions control APIs                | Use for drain/throttle/replay toggles, not hidden business flow                             |

## Modern AWS conventions (2025-2026)

### SDK versions

- **Go**: use `github.com/aws/aws-sdk-go-v2`. The v1 SDK `aws-sdk-go` is in maintenance mode; new code should not start there.
- **TypeScript/Node**: use `@aws-sdk/client-*` (v3, modular). The monolithic `aws-sdk` v2 is end-of-life as of 2024.
- **Python**: latest `boto3` / `botocore`. **Java**: AWS SDK for Java 2.x. **.NET**: AWS SDK for .NET v3+. Track the latest major SDK line per AWS docs.

### Lambda Powertools

For Lambda handlers in production, prefer Powertools over reimplementing the same primitives:

- **Python**: `aws_lambda_powertools` - idempotency util (DynamoDB-conditional-put + TTL), batch processor (partial batch response), structured logger, tracer, metrics.
- **TypeScript**: `@aws-lambda-powertools/*`.
- **Java**: `software.amazon.lambda:powertools-*`.
- **Go**: `github.com/aws/aws-lambda-powertools-go-v2` - lighter-weight, structured logger and metrics; idempotency helper available.

The Powertools idempotency utilities implement exactly the DynamoDB conditional-put + TTL pattern this skill recommends. Use them rather than hand-rolling another inbox table.

### EventBridge Pipes (modern recommendation)

Pipes (`source -> filter -> enrich -> target`) is the AWS-recommended way to do simple integration without Lambda glue. Lower latency and cost than Lambda-as-router. Use Pipes when:

- You need to filter or lightly transform events between services (SQS -> Step Functions, DynamoDB Streams -> EventBridge bus, Kinesis -> SQS).
- The integration is straightforward enough that a Lambda function would be cargo-culted glue.

Avoid Pipes when business logic is non-trivial - keep that in Lambda or Step Functions. Enrichment steps in a Pipe should be format/shape changes, not business decisions.

### Step Functions Standard vs Express

| Mode     | Use when                                                                       | Cost shape                                |
| -------- | ------------------------------------------------------------------------------ | ----------------------------------------- |
| Standard | Long-running (>5 min), durable history, audit/compliance, human approval steps | Per state transition; expensive at high TPS |
| Express  | Short, high-TPS, sub-5-min flows that need workflow expression but not full audit | Per duration + per request; cheap at high TPS |

Rule of thumb: pick **Standard** if the workflow ever waits for human approval, signals, scheduled events, or needs full execution history for audit. Pick **Express** if it is a synchronous orchestration of fast activities (a few seconds total) at high volume.

### SQS visibility timeout interlock

The single most common SQS bug is misaligned timeouts. Hold this rule:

> `visibility_timeout >= max_handler_time + downstream_timeout + jitter_buffer`

- Cap: visibility timeout maxes at 12 hours. If your handler can run that long, switch to a long-running consumer (ECS/EKS) and extend the visibility while processing (`ChangeMessageVisibility`), or rearchitect with Step Functions.
- For Lambda + SQS, also tune `MaximumBatchingWindowInSeconds` and `BatchSize` together with `reportBatchItemFailures` so partial batch response actually works and succeeded records are not retried.

```go
// Pattern: Competing Consumers with explicit visibility extension.
func process(ctx context.Context, msg sqstypes.Message) error {
	// Extend visibility before long downstream call.
	_, _ = sqsClient.ChangeMessageVisibility(ctx, &sqs.ChangeMessageVisibilityInput{
		QueueUrl:          &queueURL,
		ReceiptHandle:     msg.ReceiptHandle,
		VisibilityTimeout: 600, // seconds
	})
	return handleDownstream(ctx, msg)
}
```

## SQS

Use SQS for Point-to-Point Channel and Competing Consumers.

Production defaults:

- Set visibility timeout longer than maximum processing time, or extend it while processing.
- Use DLQ redrive policy and alarm on first critical DLQ message.
- For Lambda consumers, enable partial batch response so one bad record does not replay the whole successful batch.
- Set max receive count intentionally; too low causes transient DLQ noise, too high delays poison-message visibility.
- Use long polling for worker consumers.
- Use FIFO only when per-message-group ordering matters; choose message group id carefully to avoid hot groups.
- Treat FIFO dedupe as finite-window producer-side protection, not a replacement for consumer idempotency.

Patterns to name: Point-to-Point Channel, Competing Consumers, Idempotent Receiver, Dead Letter Channel, Message Expiration.

## SNS

Use SNS for simple Publish-Subscribe Channel and fan-out to SQS, Lambda, HTTPS, email/SMS, or mobile push.

Production defaults:

- Prefer SNS -> SQS for durable subscribers instead of direct Lambda/HTTP where buffering matters.
- Use subscription filter policies as Selective Consumer/Message Filter, not business logic.
- Configure DLQ for subscriptions where supported and monitor delivery failures.
- Sign and verify HTTPS deliveries across trust boundaries.
- Keep message attributes consistent with AsyncAPI/CloudEvents metadata.

Patterns to name: Publish-Subscribe Channel, Durable Subscriber, Selective Consumer, Dead Letter Channel.

## EventBridge

Use EventBridge for event bus routing, SaaS/AWS integration, cross-account routing, archives, replay, and API destinations.

Production defaults:

- Use event patterns as Content-Based Router rules.
- Use Archive + Replay when replay is a product/ops requirement.
- Attach DLQs to targets where failure matters.
- Treat custom event buses as owned integration surfaces with contracts.
- Avoid rule sprawl: every rule needs owner and purpose.
- EventBridge Pipes can connect source -> filter/enrich -> target for Channel Adapter, Content-Based Router, and Message Translator, but enrichment must not hide complex business logic.

Patterns to name: Message Bus, Content-Based Router, Message Filter, Messaging Bridge, Wire Tap, Message Store, Smart Proxy.

## Lambda event source mappings

Lambda event source mappings are Message Endpoints for SQS, Kinesis, DynamoDB Streams, MSK, and other sources.

Production defaults:

- For streams, decide batch size, maximum batching window, retry attempts, bisect-on-error, and on-failure destination.
- For SQS, use partial batch response for per-message failures.
- For Kinesis/DynamoDB Streams, understand shard-level ordering and blocked shards from poison records.
- Keep handlers idempotent and timeout-aware.
- Emit per-record metrics, not only per-invocation metrics.

Patterns to name: Event-Driven Consumer, Message Dispatcher, Idempotent Receiver, Dead Letter Channel.

## Kinesis Data Streams

Use Kinesis for ordered per-shard event streams, high-throughput ingestion, and replay within retention.

Production defaults:

- Partition key controls ordering and shard load; hot keys throttle.
- Enhanced fan-out can isolate consumers when throughput matters.
- Consumers need checkpointing and idempotency.
- Poison records can block a shard if retry policy is not bounded.
- Use Firehose/S3 for archival Message Store when needed.

Patterns to name: Publish-Subscribe Channel, Durable Subscriber, Message Store, Resequencer where needed.

## Amazon MSK / Kafka on AWS

Use MSK when Kafka semantics, replay, partitions, stream processing, or Kafka ecosystem tools are required.

Production defaults:

- Use Schema Registry or AWS Glue Schema Registry and CI compatibility checks.
- Use `acks=all`, idempotent producer, and meaningful partition key.
- Use consumer groups for Competing Consumers.
- Do not rely on Kafka transactions for external DB/API side effects; still use idempotency.
- Use MSK Connect/Debezium for outbox CDC where appropriate.

Patterns to name: Message Bus, Publish-Subscribe Channel, Datatype Channel, Transactional Outbox, Idempotent Receiver.

## DynamoDB Streams

Use DynamoDB Streams for CDC from DynamoDB-owned state.

Production defaults:

- Treat stream records as Event Messages derived from table changes, not necessarily stable public contracts.
- Translate internal stream records to public integration events when crossing service boundaries.
- Lambda consumers must handle duplicates and shard ordering.
- Use conditional writes and TTL for idempotency/inbox records.

Patterns to name: Channel Adapter, Event Message, Message Translator, Idempotent Receiver.

## Step Functions

Use Step Functions Standard for AWS-native Process Manager/Saga flows. Express can fit high-volume short workflows, but choose deliberately based on duration, auditability, and cost.

Production defaults:

- Model retries and catches explicitly.
- Add compensation states for success-then-failure cases.
- Keep task payloads small; use Claim Check for large data.
- Make Lambda/ECS activities idempotent by workflow execution id or business key.
- Publish domain events at workflow milestones if other services need to react.
- Surface stuck/failed executions in alarms and dashboards.

Patterns to name: Process Manager, Command Message, Event Message, Routing Slip, Scatter-Gather, Aggregator.

## S3 as Claim Check and File Transfer

Use S3 both as File Transfer and Claim Check backing store.

Production defaults:

- Include bucket, key, version id if enabled, etag, size, checksum, content type, and expiry/lifecycle in the message.
- Use least-privilege object access and encryption.
- Use S3 event notifications/EventBridge as Channel Adapter, but dedupe notifications.
- Do not put sensitive object contents into message logs or DLQs.

Patterns to name: File Transfer, Claim Check, Channel Adapter, Message Expiration.

## AWS observability

CloudWatch and X-Ray are useful, but still propagate W3C trace context when crossing brokers and non-AWS services.

Required signals:

- SQS age of oldest message, visible/not-visible count, DLQ depth.
- Lambda iterator age for streams, errors, throttles, duration, concurrency.
- EventBridge failed invocations, throttled rules, DLQ depth.
- Kinesis iterator age, read/write throttles, shard-level hot spots.
- MSK consumer lag/age, under-replicated partitions, broker disk.
- Step Functions failed/timed-out executions, retries, compensation count.

## AWS review questions

- Is this SQS Standard or FIFO, and what ordering guarantee is actually required?
- What is the visibility timeout relative to handler timeout and downstream timeout?
- Does Lambda use partial batch response where a batch can partially succeed?
- Does every EventBridge/SNS target have an owner and failure path?
- Is EventBridge archive/replay enabled only for replay-safe consumers?
- Is the DynamoDB conditional put/inbox TTL long enough for replay and retries?
- Does Step Functions model compensation explicitly?
- Are IAM permissions per producer/consumer least-privilege?
- Are message bodies, attributes, DLQs, logs, and traces free of secrets?
- Can support redrive safely without overwhelming downstream systems?

## Official AWS docs to check

- SQS FIFO exactly-once processing: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues-exactly-once-processing.html
- SQS dead-letter queues: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html
- SNS message filtering: https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html
- EventBridge event patterns: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html
- EventBridge archive and replay: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-archive.html
- EventBridge Pipes: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-pipes.html
- Lambda partial batch response: https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-errorhandling.html
- Lambda with Kinesis: https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html
- DynamoDB Streams and Lambda: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.Lambda.html
- Step Functions error handling: https://docs.aws.amazon.com/step-functions/latest/dg/concepts-error-handling.html
- AWS Glue Schema Registry: https://docs.aws.amazon.com/glue/latest/dg/schema-registry.html
