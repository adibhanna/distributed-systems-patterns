# Using this skill with Claude Code

Claude Code discovers skills under `~/.claude/skills/<name>/SKILL.md`. This project already has the required `SKILL.md` frontmatter.

## Install with a symlink

Use a symlink while developing the skill so edits are picked up immediately:

```bash
mkdir -p ~/.claude/skills
ln -s ~/.agents/skills/distributed-systems-patterns ~/.claude/skills/distributed-systems-patterns
```

Verify:

```bash
ls -la ~/.claude/skills/distributed-systems-patterns
sed -n '1,5p' ~/.claude/skills/distributed-systems-patterns/SKILL.md
```

You should see YAML frontmatter with `name: distributed-systems-patterns`.

## Project-scoped install

For a team repository:

```bash
mkdir -p .claude/skills
cp -R ~/.agents/skills/distributed-systems-patterns .claude/skills/distributed-systems-patterns
```

Commit `.claude/skills/distributed-systems-patterns/` if the whole team should share the skill.

## Activation

Claude should activate the skill when the prompt or code mentions Kafka, RabbitMQ, SQS/SNS, Pub/Sub, EventBridge, NATS, Temporal, outbox, saga, DLQ, retries, idempotency, AsyncAPI, CloudEvents, Kubernetes, KEDA, service mesh, circuit breakers, autoscaling, sharding, caching, multi-region, SLOs, or similar distributed-systems signals.

To force it:

```text
Use the distributed-systems-patterns skill to review this Go Kafka consumer for production readiness.
```

## Good verification prompt

```text
Which systems, integration, and distributed systems patterns apply here?
Answer the reliability and scale/resilience questions and tell me what blocks production readiness.
```

Expected behavior:

- Names patterns.
- Names distributed systems patterns when scale, consistency, or resilience is the main risk.
- Flags anti-patterns.
- Uses Go examples when showing code.
- Loads `reference/checklist.md` for review.
- Loads `reference/go-examples.md` for implementation snippets.

## Updating the skill

Edit `SKILL.md` first, then keep `AGENTS.md` aligned for tools that do not use Claude skills. Keep long examples in `reference/`.
