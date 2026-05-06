# Using this skill with any agent

This project is plain Markdown, so any AI coding agent that accepts rules, skills, memory, pinned files, or `@file` context can use it.

Use `SKILL.md` when the tool supports skill frontmatter. Use `AGENTS.md` when the tool auto-loads agent instructions or does not understand skill frontmatter.

## OpenCode

OpenCode treats `skills/<name>/SKILL.md` as a skill:

```bash
mkdir -p skills
ln -s ~/.agents/skills/distributed-systems-patterns skills/distributed-systems-patterns
```

Then ask:

```text
Use the distributed-systems-patterns skill to implement an idempotent Go consumer with DLQ.
```

## Aider

One-off:

```bash
aider --read ~/.agents/skills/distributed-systems-patterns/AGENTS.md \
      --read ~/.agents/skills/distributed-systems-patterns/reference/checklist.md \
      --read ~/.agents/skills/distributed-systems-patterns/reference/go-examples.md
```

Persistent `~/.aider.conf.yml`:

```yaml
read:
  - ~/.agents/skills/distributed-systems-patterns/AGENTS.md
  - ~/.agents/skills/distributed-systems-patterns/reference/checklist.md
```

## Cline / Roo Code

Project-scoped:

```bash
cp ~/.agents/skills/distributed-systems-patterns/AGENTS.md .clinerules
```

For implementation-heavy work, also attach `reference/go-examples.md` in the chat.

## Continue

```bash
mkdir -p ~/.continue/rules
cp ~/.agents/skills/distributed-systems-patterns/AGENTS.md ~/.continue/rules/distributed-systems-patterns.md
```

## Gemini CLI

Gemini CLI reads `GEMINI.md`:

```bash
mkdir -p ~/.gemini
cat ~/.agents/skills/distributed-systems-patterns/AGENTS.md >> ~/.gemini/GEMINI.md
```

Project-scoped:

```bash
cat ~/.agents/skills/distributed-systems-patterns/AGENTS.md >> ./GEMINI.md
```

## Windsurf / Codeium

```bash
cp ~/.agents/skills/distributed-systems-patterns/AGENTS.md ./.windsurfrules
```

## GitHub Copilot Chat

Copilot Chat usually works best with per-chat files:

- Attach `SKILL.md` for the operating procedure.
- Attach `reference/checklist.md` for review.
- Attach `reference/go-examples.md` for implementation prompts.

## Web-based agents

Upload or paste:

1. `SKILL.md`
2. `reference/checklist.md`
3. The one reference file needed for the task, usually `reference/decision-tree.md`, `reference/distributed-systems-guide.md`, `reference/go-examples.md`, or `reference/message-contract-template.md`.

## Good generic prompt

```text
Apply the distributed-systems-patterns skill in SKILL.md to this task.
Before coding, name the systems, integration, and distributed systems patterns, then answer the reliability and scale/resilience questions.
Use Go examples unless my repo language is different.
```
