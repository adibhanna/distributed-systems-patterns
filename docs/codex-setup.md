# Using this skill with Codex CLI

Codex auto-loads `AGENTS.md` from the workspace root and from global Codex instructions. This project ships an `AGENTS.md` that is self-contained and links to the deeper reference files.

## Option 1 - Project install

Best for repositories that regularly ship integration, messaging, distributed systems, or platform code:

```bash
ln -s ~/.agents/skills/distributed-systems-patterns/AGENTS.md ./AGENTS.md
ln -s ~/.agents/skills/distributed-systems-patterns/reference ./reference
```

If the project already has `AGENTS.md`, append the distributed architecture content manually or add a short pointer to `~/.agents/skills/distributed-systems-patterns/AGENTS.md`.

## Option 2 - On-demand install

Best for occasional reviews:

```bash
codex "Use @~/.agents/skills/distributed-systems-patterns/AGENTS.md, @~/.agents/skills/distributed-systems-patterns/reference/checklist.md, \
and @~/.agents/skills/distributed-systems-patterns/reference/go-examples.md to review src/inventory/consumer.go."
```

In interactive mode:

```text
@~/.agents/skills/distributed-systems-patterns/AGENTS.md
@~/.agents/skills/distributed-systems-patterns/reference/checklist.md

Review the Kafka producer and consumer in this repo.
Name the patterns, answer the reliability checklist, and flag production blockers.
```

## Option 3 - Global install

Use only if most Codex work is integration-heavy or distributed-systems-heavy:

```bash
mkdir -p ~/.codex
cat ~/.agents/skills/distributed-systems-patterns/AGENTS.md >> ~/.codex/AGENTS.md
```

Global install makes the activation policy visible in every workspace, which can be too aggressive for UI-only or local-only projects.

## Verify

Ask Codex:

```text
What is your activation policy for integration, messaging, event-driven code, scaling, and distributed systems?
```

If loaded, Codex should mention pattern naming, the 8 reliability questions, distributed-systems checks, anti-patterns, Go-first examples, and references under `reference/`.

## Useful Codex prompts

```text
Use the distributed-systems-patterns skill to implement a Transactional Outbox in Go.
Show the reliability checklist answers before editing code.
```

```text
Review this PR as an integration patterns production-readiness review.
Lead with findings and cite file/line references.
```

```text
Design an AsyncAPI + CloudEvents contract for payments.authorized.v1.
Use reference/message-contract-template.md.
```
