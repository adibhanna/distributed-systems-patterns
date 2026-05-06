---
description: Design or review a message contract — CloudEvents + AsyncAPI + schema, written to schema and contract files
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

7. Before writing, run a Glob for `docs/designs/*<slug>*.md`, `docs/architecture/*<slug>*.md`, `docs/adr/*<slug>*.md`, `docs/contracts/<channel>*.md`, `schemas/<channel>*`, `asyncapi/<channel>*.yaml`, `docs/runbooks/*<channel>*.md`. Use matches to populate the `## Related artifacts` section of the `docs/contracts/<channel>.md` file with concrete relative paths; for peers that don't exist yet, list the conventional path with a `(not yet written)` annotation.

8. **Update the per-service index and system catalog.** After writing the main artifact, also create or update:
   - `docs/services/<slug>/README.md` - the per-service entry point. The slug here is the *producing service* of the channel (not the channel name itself); the producer must be named in the contract. Append/update the `Channels owned` subsection with a link to the new contract, and ensure the relevant Artifacts subsection (Contracts) lists this contract. If the file does not exist, create it from the template in SKILL.md item 16.
   - `docs/system/catalog.md` - the system-level service registry. Append/update the row for the producer service `<slug>`. If the file does not exist, create it from the template in SKILL.md item 17.
   These updates are part of the same command turn; do not leave them for a follow-up.

## Output

**Write three files** for each contract (use the channel name as slug, e.g. `orders.placed.v1`):

1. `schemas/<channel>.json` (or `.avsc` for Avro, `.proto` for Protobuf) — the payload schema only.
2. `asyncapi/<channel>.yaml` — the full AsyncAPI 3.1 spec for that channel.
3. `docs/contracts/<channel>.md` — the human-readable contract: owner, patterns, compatibility mode, versioning policy, PII classification, retention, DLQ, replay policy, and the CloudEvents envelope example. Include the contract checklist from `reference/message-contract-template.md` answered point-by-point.

Only the `docs/contracts/<channel>.md` file gets the Summary + Related artifacts sections (schemas and AsyncAPI files have their own format).

In `docs/contracts/<channel>.md`, prepend:

```markdown
## Summary
- **Status**: Draft | Active | Deprecating | Retired
- **Date**: <YYYY-MM-DD>
- **Channel**: `<channel>` (e.g. `orders.placed.v1`)
- **Owner**: <team/escalation>
- **TL;DR**: 1-sentence purpose.

## System concerns
- **Owner team**: <team / Slack / on-call escalation>
- **Tenancy**: <single-tenant | multi-tenant w/ specified isolation>
- **Compliance**: <none | PII | GDPR | SOC2 | PCI | data residency>
- **Cost owner**: <team / cost center / per-event budget>
- **Capacity**: <expected p50/p99 volume; growth assumption>
- **DR posture**: <RPO | RTO | region strategy>
- **Lifecycle**: <creation date; deprecation trigger; replacement plan>
```

Append:

```markdown
## Related artifacts
- Schema: `schemas/<channel>.<ext>` (this contract's payload schema)
- AsyncAPI: `asyncapi/<channel>.yaml` (channel and operation spec)
- Design that requires this contract: `docs/designs/<slug>-design.md` (link if found)
- Producer service: <name>
- Consumer services: <names>
- Runbooks: `docs/runbooks/` (DLQ triage, replay, schema rollback for this channel)
```

Create parent directories as needed. If a file with the same name exists, ask before overwriting.

Emit a one-line confirmation in chat: `Contract <channel> written: schemas/..., asyncapi/..., docs/contracts/...`. Do not paste the schemas back into chat. If the user explicitly says "show in chat" or "don't write files", respond conversationally instead.
