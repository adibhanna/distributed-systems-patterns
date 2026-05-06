# Distributed Systems Patterns Skill

<p align="left">
  <img src="./logo.jpg" alt="Distributed Systems Patterns logo" width="600">
</p>

A portable AI-agent skill for designing, implementing, documenting, and reviewing distributed systems, integration, messaging, event-driven architecture, microservices, enterprise scaling, resilience, cloud platforms, and cross-service workflow code.

It combines modern integration, messaging, event-driven architecture, workflow, distributed systems, platform engineering, and enterprise operations guidance: Kafka/Redpanda, RabbitMQ, SQS/SNS/EventBridge, Pub/Sub, Service Bus/Event Grid, NATS, Pulsar, Debezium, CloudEvents, AsyncAPI, Schema Registry, OpenTelemetry, Temporal, Step Functions, Camunda, Kubernetes, KEDA, service mesh, Envoy, Dapr, caching, sharding, multi-region, SLOs, and enterprise governance. Code examples are Go-first.

## What the skill makes agents do

When activated, the agent must:

1. Name the integration, distributed-systems, resilience, workflow, and architecture pattern(s) in play.
2. Answer the 8 reliability questions before coding or approving code.
3. Answer distributed-systems questions when the risk is service boundaries, scale, consistency, resilience, multi-region, or enterprise operations.
4. Flag anti-patterns such as dual-write, missing idempotency, unbounded retries, ack-before-commit, DLQs with no owner, distributed monoliths, retry storms, and unbounded queues.
5. Map the pattern to modern tooling.
6. Generate production-oriented Go examples unless the repository is clearly in another language.
7. Add pattern comments in integration code, for example `// Pattern: Transactional Outbox - avoids dual-write`.
8. Use the review checklist before calling a change production-ready.

## Layout

```text
skill/
├── README.md
├── SKILL.md                         # canonical skill with YAML frontmatter
├── AGENTS.md                        # cross-tool entry point for Codex/OpenCode/Aider/etc.
├── CHANGELOG.md                     # version history
├── skill.schema.json                # skill metadata schema
├── .gitignore
├── .github/
│   └── workflows/
│       └── validate.yml             # CI validation workflow
├── agents/
│   └── openai.yaml                  # OpenAI/Codex UI metadata
├── reference/
│   ├── catalog.md                   # systems and messaging pattern catalog
│   ├── agent-workflow.md            # agent lifecycle and output templates
│   ├── architecture-documentation.md # design docs, RFCs, ADRs, migration plans
│   ├── architecture-examples.md      # filled ADR/RFC examples
│   ├── aws-service-mapping.md       # AWS services mapped to system design concepts
│   ├── checklist.md                 # production review gates
│   ├── cost-and-finops.md           # cost ownership, FinOps, and budgeting
│   ├── decision-tree.md             # problem -> pattern lookup
│   ├── distributed-systems-guide.md # scale, resilience, boundaries, multi-region
│   ├── evaluation-prompts.md        # prompts to test skill behavior
│   ├── failure-modes.md             # failure catalog and mitigations
│   ├── go-examples.md               # Go producer/consumer/workflow snippets
│   ├── go-implementation-patterns.md # Go resilience/concurrency patterns
│   ├── grpc-streaming.md            # gRPC streaming patterns
│   ├── llm-workflow-patterns.md     # LLM workflow and orchestration patterns
│   ├── maturity-model.md            # maturity levels and next steps
│   ├── message-contract-template.md # CloudEvents + AsyncAPI starter
│   ├── modern-integration-field-guide.md # modern event-driven architecture guidance
│   ├── non-go-pointers.md           # Java/TypeScript/Python pointers
│   ├── operational-runbooks.md      # incident/runbook templates
│   ├── platform-service-mapping.md  # GCP/Azure/open-source mapping
│   ├── production-guide.md          # ownership, SLOs, runbooks, platform choice
│   ├── scenario-playbooks.md        # common end-to-end architectures
│   ├── schema-migration.md          # schema evolution and migration playbooks
│   ├── security-compliance.md       # PII, IAM, tenancy, webhooks, audit
│   ├── testing-strategy.md          # contract/replay/failure/load tests
│   └── webhook-security-go.md       # Go webhook signature verification
├── scripts/
│   └── validate_skill.sh            # local package validation
└── docs/
    ├── any-agent-setup.md
    ├── claude-code-setup.md
    ├── codex-setup.md
    └── cursor-setup.md
```

`SKILL.md` is the canonical skill. `AGENTS.md` mirrors the activation policy and hard rules for tools that load `AGENTS.md`. The `reference/` directory is progressive disclosure: agents load only the file needed for the current task.

## Quick install

Recommended global layout:

```text
~/.agents/skills/distributed-systems-patterns   # source of truth
~/.codex/AGENTS.md                          # appended activation rules
~/.claude/skills/distributed-systems-patterns   # symlink
```

If you are developing from this checkout, register it as your canonical skill:

```bash
mkdir -p ~/.agents/skills
ln -s "$(pwd)" ~/.agents/skills/distributed-systems-patterns
```

If this repo is already copied into `~/.agents/skills/distributed-systems-patterns`, skip that step and create tool-specific symlinks below.

## Global Install

Use one canonical copy under `~/.agents/skills`, then symlink each agent to it. This keeps edits in one place.

```bash
SKILL_DIR="$HOME/.agents/skills/distributed-systems-patterns"

# Codex auto-loads ~/.codex/AGENTS.md; append the activation rules to the user's global Codex agent file.
mkdir -p ~/.codex
cat ~/.agents/skills/distributed-systems-patterns/AGENTS.md >> ~/.codex/AGENTS.md

mkdir -p "$HOME/.claude/skills"
ln -s "$SKILL_DIR" "$HOME/.claude/skills/distributed-systems-patterns"
```

OpenCode reads project-relative `skills/<name>/SKILL.md` rather than a global skills directory; see [`docs/any-agent-setup.md`](docs/any-agent-setup.md) for the per-project recipe.

For project-level agents that only auto-load `AGENTS.md`, symlink the portable entry point into the project:

```bash
ln -s "$HOME/.agents/skills/distributed-systems-patterns/AGENTS.md" ./AGENTS.md
```

If a project already has `AGENTS.md`, append a short pointer instead:

```markdown
Use the Distributed Systems Patterns skill at
`~/.agents/skills/distributed-systems-patterns/AGENTS.md` for distributed systems,
messaging, resilience, workflow, architecture, and production-readiness work.
```

Test the global install in a new agent session:

```text
Use the distributed-systems-patterns skill to create an architecture doc for an order fulfillment system.
Use Go services, Postgres, Kafka, Temporal, CloudEvents, OpenTelemetry, and AWS where appropriate.
Include alternatives, trade-offs, rollout, failure modes, and verification.
```

### Claude Code

```bash
mkdir -p ~/.claude/skills
ln -s ~/.agents/skills/distributed-systems-patterns ~/.claude/skills/distributed-systems-patterns
```

### Codex CLI

For a distributed-systems-heavy, integration-heavy, or architecture-heavy project:

```bash
ln -s ~/.agents/skills/distributed-systems-patterns/AGENTS.md ./AGENTS.md
ln -s ~/.agents/skills/distributed-systems-patterns/reference ./reference
```

For one task:

```bash
codex "Use @~/.agents/skills/distributed-systems-patterns/AGENTS.md and @~/.agents/skills/distributed-systems-patterns/reference/checklist.md \
to review my Kafka consumer for production readiness."
```

When developing from this checkout, substitute `$(pwd)` for `~/.agents/skills/distributed-systems-patterns` in the commands above.

### Cursor

```bash
mkdir -p .cursor/rules
cp ~/.agents/skills/distributed-systems-patterns/SKILL.md .cursor/rules/distributed-systems-patterns.mdc
```

### OpenCode and other agents

See [`docs/any-agent-setup.md`](docs/any-agent-setup.md).

## Example prompt

```text
Use the distributed-systems-patterns skill to design an order-created event flow in Go.
Use Postgres, Kafka, CloudEvents, AsyncAPI, OpenTelemetry, and a DLQ.
Show the reliability checklist answers before code.
```

Expected shape of the answer:

```text
Patterns: Event Message + Datatype Channel + Transactional Outbox + Idempotent Receiver
Reliability: at-least-once, dedupe by CloudEvents id in Redis, per-order ordering, ...
Anti-patterns: direct DB commit followed by kafka send would be a dual-write
Modern realization: Postgres outbox + Debezium -> Kafka, CloudEvents, AsyncAPI, OTel
Implementation: Go snippets with pattern comments
Verification: checklist + tests
```

## Reference guide

- [`reference/catalog.md`](reference/catalog.md) - look up a named pattern and modern tool choices.
- [`reference/agent-workflow.md`](reference/agent-workflow.md) - lifecycle, review templates, and agent behavior rules.
- [`reference/architecture-documentation.md`](reference/architecture-documentation.md) - architecture docs, RFCs, ADRs, implementation plans, migration plans, and review rubrics.
- [`reference/architecture-examples.md`](reference/architecture-examples.md) - filled ADR/RFC examples for common decisions.
- [`reference/distributed-systems-guide.md`](reference/distributed-systems-guide.md) - distributed systems, enterprise scaling, resilience, service boundaries, and governance.
- [`reference/modern-integration-field-guide.md`](reference/modern-integration-field-guide.md) - modern event-driven architecture guidance.
- [`reference/aws-service-mapping.md`](reference/aws-service-mapping.md) - AWS service mapping while keeping the skill cloud-neutral.
- [`reference/platform-service-mapping.md`](reference/platform-service-mapping.md) - GCP, Azure, Kafka/RabbitMQ/NATS/Pulsar, and cloud-neutral mapping.
- [`reference/scenario-playbooks.md`](reference/scenario-playbooks.md) - ready-to-adapt architectures for common scenarios.
- [`reference/failure-modes.md`](reference/failure-modes.md) - failure catalog for design reviews and incidents.
- [`reference/testing-strategy.md`](reference/testing-strategy.md) - test strategy for distributed systems and messaging.
- [`reference/security-compliance.md`](reference/security-compliance.md) - security, PII, tenant isolation, webhook, and audit guidance.
- [`reference/operational-runbooks.md`](reference/operational-runbooks.md) - DLQ, replay, lag, schema rollback, workflow, and failover runbooks.
- [`reference/maturity-model.md`](reference/maturity-model.md) - team/platform maturity assessment and next steps.
- [`reference/evaluation-prompts.md`](reference/evaluation-prompts.md) - prompts to validate skill behavior.
- [`reference/decision-tree.md`](reference/decision-tree.md) - start here when the problem is known but the pattern is not.
- [`reference/checklist.md`](reference/checklist.md) - use before merge or production-readiness claims.
- [`reference/go-examples.md`](reference/go-examples.md) - Go snippets for outbox, idempotent consumer, DLQ, retry, and Temporal Process Manager.
- [`reference/go-implementation-patterns.md`](reference/go-implementation-patterns.md) - Go worker, timeout, idempotency, shutdown, and workflow patterns.
- [`reference/message-contract-template.md`](reference/message-contract-template.md) - CloudEvents and AsyncAPI starter for new channels.
- [`reference/production-guide.md`](reference/production-guide.md) - enterprise ownership, SLO, runbook, platform, and security guidance.
- [`reference/webhook-security-go.md`](reference/webhook-security-go.md) - webhook signature verification, timestamp windows, replay-window dedup, Go example.
- [`reference/schema-migration.md`](reference/schema-migration.md) - concrete walkthrough for adding/renaming/removing event-contract fields without breaking consumers.
- [`reference/cost-and-finops.md`](reference/cost-and-finops.md) - cost-aware operation: retention, per-event pricing, cross-region egress, queue depth vs spend.
- [`reference/grpc-streaming.md`](reference/grpc-streaming.md) - gRPC server-streaming, bidirectional streams, deadlines, retry interceptors, status codes.
- [`reference/llm-workflow-patterns.md`](reference/llm-workflow-patterns.md) - async LLM inference queueing, bounded retry, model-output validation, streaming token handoff.
- [`reference/non-go-pointers.md`](reference/non-go-pointers.md) - minimal pointers for Java/Spring Cloud Stream, TypeScript/NestJS, Python/FastAPI consumers.

## Maintenance

When changing the skill:

1. Update `SKILL.md` first.
2. Keep `AGENTS.md` aligned with activation rules, mandatory process, code rules, and references.
3. Keep `agents/openai.yaml` aligned with the skill name and user-facing description.
4. Keep large examples in `reference/`, not in `SKILL.md`.
5. Prefer Go examples.
6. Check for stale references to non-Go default examples or single-tool assumptions.
7. Run `bash scripts/validate_skill.sh` and ensure CI workflow `.github/workflows/validate.yml` passes.

Run local validation:

```bash
./scripts/validate_skill.sh
```

## License

MIT. See [`LICENSE`](LICENSE).

## Scope

This is a practical pattern language and agent workflow for distributed systems and enterprise-scale service design. It helps AI coding agents apply shared vocabulary, reliability questions, scale/resilience checks, anti-pattern gates, and modern implementation defaults during day-to-day engineering work.
