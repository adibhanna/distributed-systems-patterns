---
description: Design or review a message contract — CloudEvents + AsyncAPI + schema, written to schema and contract files
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/message-contract-template.md` for the envelope and AsyncAPI starter, and `reference/schema-migration.md` for the add/rename/remove walkthrough.

Design or review one message contract. Keep business rules out of envelopes and translators.

1. **Determine the producer feature.** A contract belongs to the feature whose service produces the channel. Glob `docs/features/*/README.md` for any service that lists this channel under "Channels owned" as `produced`. If found, use that feature's slug. If multiple match (rare), ask the user. If none match, ask the user "Which feature/service produces this channel?" and use the answer as the slug.
2. State the owning team, escalation path, channel name (semantic and versioned, for example `orders.placed.v1`), and the patterns in play: Event Message vs Command Message, Datatype Channel, Publish-Subscribe vs Point-to-Point, Idempotent Receiver, Claim Check if payloads are large.
3. Produce the CloudEvents 1.0.2 envelope with required fields (`id`, `source`, `type`, `subject`, `time`, `specversion`, `datacontenttype`) and the convention extensions used in this skill (`correlationid`, `causationid`, `partitionkey`, `traceparent`, `expirytime`). The envelope example lives in the AsyncAPI file, not the contract doc.
4. Produce the AsyncAPI 3.1 channel, operation (send/receive), message, and payload schema. Choose Avro, Protobuf, or JSON Schema and state why.
5. Declare the compatibility mode: BACKWARD (default), FORWARD, or FULL. Name the CI gate that enforces it (Schema Registry compatibility, AsyncAPI diff, JSON Schema compatibility check).
6. State the versioning policy: optional fields with defaults are minor; required fields, renamed fields, removed fields, or type changes require a new channel version with parallel `v1` + `v2` and a retirement date.
7. Classify PII in the schema, name the retention policy, name the DLQ channel and owner, and state the replay/redrive policy.

8. Before writing, run a Glob for `docs/features/<slug>/**` to enumerate peer artifacts in the producer feature. Use matches to populate the `## Related artifacts` section of the `docs/features/<slug>/contracts/<channel>.md` file with concrete relative paths; for peers that don't exist yet, list the conventional path with a `(not yet written)` annotation.

9. **Update the per-feature index and system catalog.** After writing the main artifact, also create or update:
   - `docs/features/<slug>/README.md` — the per-feature entry point (slug is the producing feature determined in step 1). Append/update `## Channels owned` with the channel name (marked `produced`), and append the new contract path to `## Artifacts.Contracts`. If the file does not exist, create it from the template in SKILL.md item 16.
   - `docs/system/catalog.md` — the system-level feature registry. Append/update the row for the producer feature `<slug>`. If the file does not exist, create it from the template in SKILL.md item 17.
   These updates are part of the same command turn; do not leave them for a follow-up.

## Output

**Write three files** for each contract under the producer feature's folder (use the channel name as slug, e.g. `orders.placed.v1`):

1. `docs/features/<slug>/schemas/<channel>.json` (or `.avsc` for Avro, `.proto` for Protobuf) — the payload schema only.
2. `docs/features/<slug>/asyncapi/<channel>.yaml` — the full AsyncAPI 3.1 spec for that channel, including the CloudEvents envelope example.
3. `docs/features/<slug>/contracts/<channel>.md` — the human-readable contract. Target ~40 lines. The contract doc points at the schema and AsyncAPI files for wire-format detail; it does not duplicate them.

Use this structure for `docs/features/<slug>/contracts/<channel>.md`:

```markdown
# Contract: `<channel>`

## Summary
- **Status**: Draft | Active | Deprecating | Retired
- **Date**: <YYYY-MM-DD>
- **Channel**: `<channel>` (e.g. `orders.placed.v1`)
- **Owner**: <team / escalation>
- **TL;DR**: 1 sentence purpose.

## Patterns
[1-2 lines naming the patterns: Event Message vs Command, Datatype Channel, Idempotent Receiver, Claim Check, etc.]

## Producer and consumers
[2-3 lines: producer service, known consumers, broker.]

## Compatibility and versioning
[2-4 lines: BACKWARD/FORWARD/FULL; CI gate; when to spin up v2; deprecation policy.]

## Ordering, idempotency, retention
- **Ordering key**: <field>
- **Idempotency key**: <field>
- **Retention**: <TTL>

## DLQ and replay
- **DLQ**: <channel> (owner: <team>)
- **Replay/redrive**: <policy>

## Related artifacts
- Schema: `../schemas/<channel>.<ext>`
- AsyncAPI: `../asyncapi/<channel>.yaml`
- Design: `../design.md`
- Per-feature README: `../README.md`
- Runbooks: `../runbooks/` (DLQ triage, replay, schema rollback for this channel)
```

Create parent directories as needed. If a file with the same name exists, ask before overwriting.

Emit a one-line confirmation in chat: `Contract <channel> written: docs/features/<slug>/schemas/..., docs/features/<slug>/asyncapi/..., docs/features/<slug>/contracts/...`. Do not paste the schemas back into chat. If the user explicitly says "show in chat" or "don't write files", respond conversationally instead.
