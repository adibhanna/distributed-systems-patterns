# Agent Workflow For Integration Tasks

Use this when the agent needs to design, implement, review, or debug integration code. It borrows proven skill-design habits from compact engineering skills: progressive disclosure, shared vocabulary, thin slices, explicit gates, and anti-rationalization tables.

## Core behavior

Keep `SKILL.md` concise. Use this file for the deeper workflow.

Every answer from this skill should follow this lifecycle:

```text
DETECT -> CLASSIFY -> CONTRACT -> RELIABILITY -> SLICE -> IMPLEMENT -> VERIFY -> OPERATE
```

## 1. Detect

Identify the task shape:

- Design: user asks for architecture, pattern choice, workflow, event flow, or broker selection.
- Implementation: user asks for code, config, schema, producer, consumer, workflow, or tests.
- Review: user asks for review, audit, PR feedback, risk, or production readiness.
- Debug: user reports duplicates, missing messages, poison messages, lag, ordering, replay, or DLQ growth.

Then load only the needed references:

- Unknown pattern: `reference/decision-tree.md`
- Pattern details: `reference/catalog.md`
- Architecture document/RFC/ADR/plan: `reference/architecture-documentation.md`
- Production readiness: `reference/checklist.md`
- Go code: `reference/go-examples.md`
- Modern traps: `reference/modern-integration-field-guide.md`
- Distributed systems and enterprise scale: `reference/distributed-systems-guide.md`
- Scenario starting points: `reference/scenario-playbooks.md`
- Failure review: `reference/failure-modes.md`
- Tests: `reference/testing-strategy.md`
- Security/compliance: `reference/security-compliance.md`
- Operations/runbooks: `reference/operational-runbooks.md`
- Cloud/platform mapping: `reference/aws-service-mapping.md` or `reference/platform-service-mapping.md`
- Contract design: `reference/message-contract-template.md`
- Ops/SLO/runbook: `reference/production-guide.md`

## 2. Classify

Name:

- Integration style: File Transfer, Shared Database, Remote Procedure Invocation, or Messaging.
- Message intent: Command, Event, Document, or Notification.
- Topology: point-to-point, publish-subscribe, request-reply, scatter-gather, splitter/aggregator, process manager.
- Consistency pattern: outbox, inbox, idempotent receiver, saga/process manager, transactional producer.

Do not start code before this classification is visible.

## 3. Contract

For any new message/channel, define:

- Channel name.
- Owner team.
- Producer(s) and consumer(s).
- CloudEvents envelope fields.
- Payload schema and compatibility mode.
- Ordering key.
- Idempotency key.
- Retention and replay policy.
- DLQ and redrive owner.
- PII/security classification.

If any contract item is unknown, state the assumption or ask one focused question.

## 4. Reliability

Run the 8-question checklist. For reviews, lead with blockers before advice.

Minimum output:

```text
Reliability:
- Delivery: at-least-once
- Idempotency: event.id in inbox table, retained 30 days
- Bad messages: orders.placed.v1.dlq, owned by Orders Platform
- Retry: 5 attempts, exponential backoff + jitter, permanent validation errors to DLQ
- Ordering: per order_id
- Schema: Protobuf subject orders.placed.v1, backward compatibility in CI
- Observability: traceparent + lag/age/DLQ/retry metrics
- Failure boundary: local transaction only; fulfillment saga handles downstream compensation
```

## 5. Slice

For implementation tasks, work in vertical slices:

1. Contract/schema and tests.
2. Producer/outbox.
3. Publisher/CDC config.
4. Consumer/idempotency.
5. Retry/DLQ.
6. Observability.
7. Replay/redrive test.

Each slice should build and have a verification step. Do not mix broad refactors with integration behavior changes.

## 6. Implement

Code rules:

- Prefer Go unless the repository clearly uses another language.
- Name patterns in comments at the point implemented.
- Keep interfaces small: producer, consumer, dedup store, clock, workflow activities.
- Make ack/commit timing explicit.
- Use structured logs and OpenTelemetry context propagation.
- Surface retries and DLQs; do not bury them behind `process()`.
- Use source-driven implementation for exact library APIs: inspect `go.mod` and official docs before framework-specific code.

## 7. Verify

Required test categories:

- Contract compatibility.
- Producer outbox transaction.
- Consumer idempotency under duplicate delivery.
- Retry classification: transient retries, permanent DLQs.
- Poison message DLQ path.
- Replay/backfill safety.
- Graceful shutdown.
- Workflow compensation/replay for Process Manager code.

For review tasks, findings lead. Use severity:

- Critical: message loss, duplicate business side effects, security exposure.
- High: dual-write, ack-before-commit, no idempotency, no DLQ, unbounded retry.
- Medium: missing schema compatibility, weak observability, unclear ownership.
- Low: naming, docs, small maintainability issues.

## 8. Operate

No production-ready claim without:

- Dashboard.
- Alert.
- DLQ owner.
- Redrive runbook.
- Retention/replay policy.
- Capacity and backpressure plan.
- Security/PII answer.

## Anti-rationalizations

| Rationalization                                        | Response                                                                                     |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| "It's just an event."                                  | Events are APIs. They need contracts and owners.                                             |
| "Kafka/SQS/Pub/Sub gives exactly once."                | Name the exact boundary. External side effects still need idempotency.                       |
| "We can add DLQ later."                                | Bad-message handling changes control flow and operations. Add it before merge.               |
| "The consumer is idempotent because it checks status." | Prove duplicate concurrent delivery cannot produce two side effects.                         |
| "Ordering does not matter."                            | Say per-key/none explicitly and name the business consequence.                               |
| "Replay is only for emergencies."                      | Emergencies are when replay safety matters most. Test it before the incident.                |
| "One events topic is simpler."                         | It centralizes complexity in every consumer. Prefer Datatype Channels.                       |
| "We will monitor broker health."                       | Broker health is not workflow health. Monitor lag/age, DLQ, retries, and end-to-end latency. |

## Review output template

```text
Patterns:
- Event Message + Datatype Channel + Transactional Outbox + Idempotent Receiver

Findings:
- High: consumer commits offset before DB write succeeds at path/file.go:123.
- Medium: no schema compatibility gate for orders.placed.v1.

Reliability checklist:
- Delivery: ...

Recommended patch:
- ...

Verification:
- ...
```

## Skill maintenance checklist

When changing this skill:

- Keep `SKILL.md` short enough to load quickly.
- Move examples and platform detail into `reference/`.
- Keep references one level deep from `SKILL.md`.
- Prefer checklists and output templates over long exposition.
- Include anti-patterns and anti-rationalizations.
- Keep Go examples current and source-check exact APIs when updating code snippets.
