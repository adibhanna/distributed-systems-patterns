---
description: Design or review a message contract — CloudEvents, AsyncAPI 3.1, schema versioning
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/message-contract-template.md` for the envelope and AsyncAPI starter, and `reference/schema-migration.md` for the add/rename/remove walkthrough.

Design or review one message contract. Keep business rules out of envelopes and translators.

1. State the owning team, escalation path, channel name (semantic and versioned, for example `orders.placed.v1`), and the patterns in play: Event Message vs Command Message, Datatype Channel, Publish-Subscribe vs Point-to-Point, Idempotent Receiver, Claim Check if payloads are large.
2. Produce the CloudEvents 1.0.2 envelope with required fields (`id`, `source`, `type`, `subject`, `time`, `specversion`, `datacontenttype`) and the convention extensions used in this skill (`correlationid`, `causationid`, `partitionkey`, `traceparent`, `expirytime`).
3. Produce the AsyncAPI 3.1 channel, operation (send/receive), message, and payload schema. Choose Avro, Protobuf, or JSON Schema and state why.
4. Declare the compatibility mode: BACKWARD (default), FORWARD, or FULL. Name the CI gate that enforces it (Schema Registry compatibility, AsyncAPI diff, JSON Schema compatibility check).
5. State the versioning policy: optional fields with defaults are minor; required fields, renamed fields, removed fields, or type changes require a new channel version with parallel `v1` + `v2` and a retirement date.
6. Classify PII in the schema, name the retention policy, name the DLQ channel and owner, and state the replay/redrive policy.
7. End with the contract checklist from `reference/message-contract-template.md` answered point-by-point.
