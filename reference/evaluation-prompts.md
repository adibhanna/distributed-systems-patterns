# Evaluation Prompts

Use these to test whether the skill works for real users. A good answer should name patterns, answer reliability/distributed-systems questions, flag anti-patterns, and propose verification.

## Review broken consumer

```text
Use the distributed-systems-patterns skill to review this consumer:
- auto-commits Kafka offsets
- writes to Postgres
- retries forever on any error
- has no DLQ
Lead with findings and propose a production-ready fix in Go.
```

Expected: flags ack-before-commit, missing Idempotent Receiver, unbounded retry, no DLQ.

## Design order workflow

```text
Design an order fulfillment workflow across orders, payments, inventory, and shipping.
Use Go services, Kafka, Postgres, Temporal, CloudEvents, and OpenTelemetry.
Produce an architecture doc with alternatives and rollout plan.
```

Expected: Transactional Outbox, Event Message, Process Manager, Command Message, compensation, idempotent activities.

## AWS mapping

```text
Map a webhook ingestion platform to AWS services without making it AWS-specific.
Use SQS/SNS/EventBridge/Lambda where appropriate and explain the integration patterns.
```

Expected: Channel Adapter, Idempotent Receiver, Message Store, DLQ, EventBridge/SQS mapping, signature verification.

## Distributed scaling

```text
Our consumer lag grows during traffic spikes and scaling CPU-based HPA does not help.
Use the distributed-systems-patterns skill to diagnose and propose a scaling design.
```

Expected: queue age/lag as signal, KEDA/HPA, partition/key analysis, downstream saturation, backpressure.

## Security review

```text
Review an event bus that carries customer profile updates with email, phone, and address fields.
What security/compliance issues block production?
```

Expected: PII minimization, schema classification, retention, DLQ/log redaction, IAM/ACLs.

## Architecture decision

```text
Write an ADR deciding between pure event choreography and Temporal for a refund workflow.
```

Expected: ADR format, alternatives, Process Manager recommendation if state/compensation/queryability matter.
