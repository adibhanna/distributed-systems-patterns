# Cost and FinOps for Distributed Messaging

Use this when capacity planning, replay windows, retry policy, or cross-region topology decisions interact with the cloud bill — which is most of the time once events scale beyond a single team. Cost is a reliability concern: budgets that no one owns get cut under pressure, and the cuts usually land on retention and replay.

## Why cost is a reliability concern

- Storage retention competes with replay needs. A 7-day retention is fine until an outage runs 9 days and the replay source is gone.
- Cross-region egress dominates global event-bus bills. A "small" mirrored topic at 10 MB/s across regions is roughly $25k/year in egress alone on most clouds.
- Per-event pricing models (EventBridge, Step Functions transitions, Pub/Sub) compound under retry storms. A bug that retries 50x for an hour is a cost incident, not just a reliability one.
- Replay and backfill are the largest unplanned spend. A full-history replay of a busy topic against five consumers can cost more than the original ingest.

## Cost levers per platform

| Platform              | Levers that move the bill (high to low)                                                                                            |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Kafka / Amazon MSK    | Retention days, compacted vs delete, partition count, replication factor (RF=2 vs 3), broker class, follower-fetch from closest replica |
| SQS                   | Retention period, polling cadence (long vs short), batch size, FIFO vs Standard pricing tier                                       |
| SNS / EventBridge     | Per-event delivery cost per target, archive retention duration, replay frequency                                                   |
| Step Functions        | State-transition count (Standard) vs duration (Express), Map iterations, error/retry transitions billed as transitions            |
| Google Pub/Sub        | Subscription throughput, message retention duration, snapshot storage, ordered-delivery overhead                                   |
| DynamoDB Streams      | Read request units per stream record, retention (24h fixed for Streams; longer with Kinesis Data Streams adapter)                  |
| Cross-region          | NAT gateway egress charges, MirrorMaker / inter-region replication bandwidth, cross-region read replicas                           |

### Kafka / MSK detail

```yaml
# Production-default tuning levers, in priority order:
retention_ms: 604800000          # 7 days; longer multiplies storage cost linearly.
cleanup_policy: delete           # `compact` for state topics; do not blindly compact event logs.
partitions: 24                   # Right-size to consumer parallelism + headroom; over-partitioning hurts.
replication_factor: 3            # 3 for durable; 2 only for non-critical and with explicit owner sign-off.
min_insync_replicas: 2           # Keep equal to RF-1 for non-lossy paths.
```

Follower-fetch from closest replica (KIP-392) cuts cross-AZ data charges substantially for read-heavy fan-out. Confirm consumers and brokers support it before assuming the saving.

### SQS detail

```yaml
retention_seconds: 345600        # 4 days; minimum that survives a long weekend.
visibility_timeout: 60           # Just above max handler time + jitter.
receive_wait_time_seconds: 20    # Long polling - free, and reduces empty-receive billing.
batch_size: 10                   # Up to 10 per receive; pricing is per-API-call.
```

Standard SQS billing is per-million requests; FIFO is per-million plus a higher rate. A noisy short-poll loop costs more than the same workload long-polled.

### Step Functions detail

Standard workflows are billed per state transition; Map states multiply transitions by element count. Express workflows are billed per duration and request — cheaper for short, high-volume workloads. The break-even is typically around 100ms per execution, but model it before committing.

```text
Standard cost ~ transitions * $0.000025
Express cost  ~ requests * $0.000001 + GB-seconds * $0.0000001
```

Retries are billed transitions. A workflow with `MaxAttempts: 5` on a flaky activity costs 5x baseline in the failure case.

## Anti-patterns

- Unbounded retention "just in case." Retention should be the longest of: replay window, audit requirement, debug window. Anything past that is paying for unused storage forever.
- Uncapped retry attempts. Combine bounded retry with DLQ; otherwise per-event pricing compounds during downstream incidents.
- High-cardinality fan-out without archival quotas. EventBridge with 200 rules and no DLQ retention plan is a multi-vendor bill, not a system.
- Cross-region active-active without measuring egress. Run `aws ce` or equivalent for one week before committing; egress is rarely the biggest line item until it suddenly is.
- Treating cost as the platform team's problem. Per-channel ownership includes per-channel budget.

## Cost-as-an-SLO pattern

Treat cost like latency or error rate: each channel has a budget, an alert threshold, and an owner.

| Channel               | Budget ($ / month)        | Alert threshold | Owner            |
| --------------------- | ------------------------- | --------------- | ---------------- |
| `orders.placed.v1`    | $850 (storage + delivery) | 80% of budget   | orders team      |
| `clickstream.events`  | $4,200                    | 80%             | analytics team   |
| `payments.audit.v1`   | $1,500 (long retention)   | 90%             | payments + risk  |

Wire alerts via the cloud billing export (AWS CUR / GCP billing export / Azure Cost Management) into the same alerting channel as latency SLOs. A cost burn alert is on-call, not a quarterly review item.

## Replay / backfill cost estimate template

```text
estimate = events * per_delivery_cost * number_of_consumers
        + events * average_payload_kb * egress_per_kb (if cross-region)
        + estimated_runtime_minutes * worker_cost_per_minute
```

Worked example, EventBridge replay of 50M events to 6 targets:

```text
50,000,000 * $1.00 / 1,000,000 * 6 = $300 in delivery
+ 50,000,000 * 4 KB * $0.02/GB = $4 egress (single region)
= ~$305 minimum, before consumer compute cost.
```

Run this estimate every time someone says "let's just replay from the beginning." If the answer surprises them, run it twice.

## References

- AWS pricing: SQS https://aws.amazon.com/sqs/pricing/, SNS https://aws.amazon.com/sns/pricing/, EventBridge https://aws.amazon.com/eventbridge/pricing/, Step Functions https://aws.amazon.com/step-functions/pricing/, MSK https://aws.amazon.com/msk/pricing/
- GCP Pub/Sub pricing: https://cloud.google.com/pubsub/pricing
- Kafka retention configuration: https://kafka.apache.org/documentation/#brokerconfigs_log.retention.ms
- AWS Cost and Usage Report: https://docs.aws.amazon.com/cur/latest/userguide/what-is-cur.html
