# Using this skill with Cursor

Cursor can use this skill as a project rule, legacy `.cursorrules`, or per-chat file context.

## Option 1 - Project rule

```bash
mkdir -p .cursor/rules
cp ~/.agents/skills/distributed-systems-patterns/SKILL.md .cursor/rules/distributed-systems-patterns.mdc
```

For scoped activation, edit the `.mdc` frontmatter:

```mdc
---
description: Apply modern distributed systems, integration, and enterprise architecture patterns when designing, writing, or reviewing messaging, event-driven, scaling, resilience, cloud/platform, or cross-service workflow code.
globs:
  - "**/consumer.{go,java,kt,ts,py,rs}"
  - "**/producer.{go,java,kt,ts,py,rs}"
  - "**/handler*.{go,java,kt,ts,py,rs}"
  - "**/events/**"
  - "**/schemas/**"
  - "**/{kafka,sqs,sns,pubsub,rabbit,nats,eventbridge}/**"
  - "**/{kubernetes,k8s,helm,terraform,infra}/**"
  - "**/*.proto"
  - "**/*.avsc"
  - "**/asyncapi.{yml,yaml,json}"
alwaysApply: false
---
```

Then keep the `SKILL.md` body below that frontmatter.

## Option 2 - Legacy `.cursorrules`

```bash
cat ~/.agents/skills/distributed-systems-patterns/AGENTS.md >> .cursorrules
```

This applies broadly to all chats in the project.

## Option 3 - Per-chat files

Add these to Cursor chat context:

```text
@~/.agents/skills/distributed-systems-patterns/SKILL.md
@~/.agents/skills/distributed-systems-patterns/reference/checklist.md
@~/.agents/skills/distributed-systems-patterns/reference/go-examples.md
```

Then ask:

```text
Review my Kafka consumer for distributed-systems-patterns production readiness.
```

## Recommended use

- Production integration or distributed-systems repository: Project rule with globs.
- Mixed repository: Per-chat files.
- Personal always-on workspace: `.cursorrules`.
