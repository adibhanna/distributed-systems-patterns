# LLM Workflow Patterns

Use this when integrating an LLM (chat, embedding, tool-use, agent) into a distributed system. Treat the model as a slow, expensive, non-deterministic remote dependency and apply the same patterns you would for any third-party API — plus a few specific to LLMs.

## Why LLM calls are not normal RPC

- Latency is measured in seconds to minutes, not milliseconds. Synchronous user-facing handlers cannot wait inline.
- Cost is per-token, not per-call. Long contexts and unbounded retries multiply spend non-linearly.
- Output is partial via streaming. Treating it as a single response blob loses the UX win and complicates failure handling mid-stream.
- Non-determinism: the same input may produce different output. Retries are not duplicate-safe in the way a deterministic side effect would be.
- Failure modes are richer than HTTP codes: rate limits (429), capacity exhaustion (529/503), context-length errors, content-policy refusals, tool-use loops that never terminate.

## Async inference queueing

Place LLM tasks behind a queue. The queue is your Bulkhead and Backpressure surface.

```text
[user request] -> [api] -> [LLM job queue: SQS/Kafka/NATS] -> [LLM worker pool] -> [result store + notify]
```

Patterns to name: Bulkhead (separate worker pool per model/tier), Backpressure (queue depth as scaling signal), Process Manager (multi-step agent loops), Idempotent Receiver (dedupe by job id), Dead Letter Channel (quarantined invalid outputs).

## Bounded retry policy

Retry on:

- 429 rate limit (with `Retry-After` honored).
- 503 / 529 / 500 with exponential backoff and jitter.
- Stream disconnect mid-output, with a resumable session id where the provider supports it.
- Network-level errors: connection reset, TLS failure, DNS.

Do not retry on:

- 400 (validation, including context-length).
- 401 / 403.
- Output-quality issues. A bad answer is not a retryable failure — it is a validation failure that goes to a quarantine path.
- Tool-call loops. Cap by step count and total token budget, not by attempt count.

Cap retries by token budget instead of attempt count for long-context tasks. A 200k-token call retried 3 times is a cost incident, not resilience.

```go
// Pattern: Bounded retry, token-budget aware.
type LLMRetryPolicy struct {
	MaxAttempts    int
	MaxTokenBudget int // total prompt+completion tokens across all attempts
	BaseDelay      time.Duration
}
```

### Token-budget worked example

Long-context tasks - RAG over many docs, multi-step agents, extraction pipelines - consume tokens unevenly across attempts. Capping by attempt count is wrong because one expensive retry on a 200k-token prompt can blow the budget that three small retries would not. Cap by tokens spent, not attempts.

```go
// Pattern: Backpressure - bound retry by tokens spent, not by attempt count.
type LLMTokenBudget struct {
	InputCap  int // total input tokens allowed across attempts
	OutputCap int // total output tokens allowed across attempts
	spent     struct{ in, out int }
}

func (b *LLMTokenBudget) TryCharge(in, out int) error {
	if b.spent.in+in > b.InputCap || b.spent.out+out > b.OutputCap {
		return ErrBudgetExhausted
	}
	b.spent.in += in
	b.spent.out += out
	return nil
}

var ErrBudgetExhausted = errors.New("llm token budget exhausted")
```

Call site: estimate input tokens from the prompt (tokenizer count or a fast heuristic), call `TryCharge` BEFORE invoking the model with the estimate, then reconcile actual usage from the response. For Anthropic that is `response.Usage.InputTokens` and `response.Usage.OutputTokens`; for OpenAI it is `response.usage.prompt_tokens` and `response.usage.completion_tokens`. Reconciliation matters - estimates drift, especially on tool-use turns where the model echoes prior messages.

On `ErrBudgetExhausted`: route the job to a quarantine / DLQ-equivalent with the spent counters attached. Do not auto-redrive without operator review - re-running the same prompt simply spends more tokens to fail again.

Caching interaction: cached input tokens are billed at roughly 10% of the normal input rate on both Anthropic and OpenAI. Charge them at the discounted rate (e.g., `b.TryCharge(cachedTokens/10 + uncachedTokens, out)`) so the budget does not punish well-cached prompts that are actually cheap.

Streaming interaction: charge based on the final `message_stop` event's usage block (Anthropic) or the last chunk's `usage` field with `stream_options: {include_usage: true}` (OpenAI). Partial streaming counts only the input cost until output is complete; do not mid-stream charge per token, since the provider's final reconciliation is the source of truth.

- When `ErrBudgetExhausted` fires repeatedly across different inputs, treat it as a degradation signal and route to the smaller-model fallback or cached-response fallback documented in the previous section.

## Output validation as Idempotent Receiver

Validate model output before committing the side effect. Treat invalid output the same way you treat a malformed event message: quarantine, do not auto-redrive without human review.

```go
// Pattern: Idempotent Receiver - validate, then commit.
// Pattern: Invalid Message Channel - quarantine invalid outputs.
func handleLLMResponse(ctx context.Context, req Request, raw string) error {
	var out PlannedAction
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return quarantine(ctx, req, raw, "invalid-json")
	}
	if err := schema.Validate(out); err != nil {
		return quarantine(ctx, req, raw, "schema-violation")
	}
	if !policy.AllowAction(out) {
		return quarantine(ctx, req, raw, "policy-denied")
	}
	return commit(ctx, req.ID, out)
}
```

Quarantined outputs go to a review queue, not a redrive loop. Auto-redriving an LLM job re-runs inference at full cost without addressing why the output was invalid.

## Streaming token handoff

Stream from the provider through your service to the client using server-sent events or gRPC server-streaming. Two rules:

1. The server-side connection from your service to the provider is independent from the client-side connection. Either can drop without killing the other.
2. Provide a resumable session id. If the client disconnects, the server keeps writing to a buffer (size-bounded) so the client can reconnect and resume.

```go
// Pattern: Publish-Subscribe Channel (single subscriber) for token streaming.
// Pattern: Claim Check - long completions go to object storage; client receives URI.
func (s *LLMServer) Stream(ctx context.Context, req Req, send func(Token) error) error {
	provider, err := s.client.StreamMessage(ctx, req.toProvider())
	if err != nil {
		return mapProviderErr(err)
	}
	defer provider.Close()

	for provider.Next() {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}
		tok := provider.Current()
		if err := send(tok); err != nil {
			// Client disconnected; keep buffering for resumable session.
			s.buffer.Append(req.SessionID, tok)
		}
	}
	return provider.Err()
}
```

## Process Manager for multi-step agents

Tool-use loops (call model, model emits tool call, run tool, feed result back, repeat) are Process Managers. Every external call is an Activity; every Activity is idempotent by `(workflow_id, tool_call_id)`.

```go
// Pattern: Process Manager - durable orchestration of tool-use loop.
func AgentWorkflow(ctx workflow.Context, in AgentInput) (AgentResult, error) {
	ctx = workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
		StartToCloseTimeout: 60 * time.Second,
		RetryPolicy: &temporal.RetryPolicy{
			MaximumAttempts: 3,
			NonRetryableErrorTypes: []string{"PolicyDeniedError", "InvalidOutputError"},
		},
	})
	state := AgentState{Messages: in.Messages}
	for step := 0; step < in.MaxSteps; step++ {
		var resp ModelResponse
		if err := workflow.ExecuteActivity(ctx, CallModel, state).Get(ctx, &resp); err != nil {
			return AgentResult{}, err
		}
		if resp.Final {
			return AgentResult{Output: resp.Content}, nil
		}
		var toolOut ToolResult
		if err := workflow.ExecuteActivity(ctx, RunTool, resp.ToolCall).Get(ctx, &toolOut); err != nil {
			return AgentResult{}, err
		}
		state.AppendToolResult(resp.ToolCall.ID, toolOut)
	}
	return AgentResult{}, fmt.Errorf("step budget exhausted")
}
```

Step Functions, Temporal, and Camunda 8 all work; the pattern matters more than the engine.

## Cost guardrails

| Layer                  | Control                                                                  |
| ---------------------- | ------------------------------------------------------------------------ |
| Per-tenant             | Daily token quota; enforce on enqueue, surface in API response headers   |
| Per-request            | Hard token cap; reject prompts above the limit before sending            |
| Per-conversation       | Running total; alert at 90%; cut off at 100%                             |
| Per-channel            | Cost-as-an-SLO budget; see `reference/cost-and-finops.md`                |
| Provider               | Use provider-level rate limits as last-line defense, not first-line      |

Alert on cost-per-conversation outliers (P99 cost > 10x median) — these are the prompts the team forgot to bound.

## Anti-patterns

- Synchronous user-facing request that calls a 60-second LLM directly. Either stream, or queue and notify; do not block the request thread.
- Unlimited retries that triple cost without checking output. Cap by token budget, not attempt count.
- Treating `temperature > 0` retries as duplicate-safe. The retry produces a different answer; combine with output validation and quarantine.
- Logging full prompts and responses with PII without redaction. Treat them as customer data; apply the same policy as message bodies.
- One worker pool for everything. Mix latency-sensitive interactive prompts with batch summarization and the batch will starve the interactive queue.
- Tool-use loop without a step cap. The agent will sometimes fail to terminate; the cap is your circuit breaker.

## Prompt caching

Both Anthropic (`cache_control` blocks) and OpenAI (automatic prompt cache) ship cache-aware prompts in 2025-2026. For LLM workers this is a cost lever as material as queue retention. Long stable prefixes - system prompt, retrieved documents, few-shot examples - should be marked cacheable; cached tokens are typically billed at ~10% of normal input rate.

The cache breaks on any change to the prefix, including whitespace. Design prompts so the cacheable prefix is stable: put dynamic content (user message, retrieved chunk for this request) at the end, not interleaved.

```go
// Pattern: Cache-Aside applied to the model provider's cache.
type AnthropicBlock struct {
	Type         string                 `json:"type"`
	Text         string                 `json:"text,omitempty"`
	CacheControl map[string]string      `json:"cache_control,omitempty"`
}

func buildPrompt(systemPrompt, retrieved, userMsg string) []AnthropicBlock {
	return []AnthropicBlock{
		// Stable prefix - mark cacheable.
		{Type: "text", Text: systemPrompt, CacheControl: map[string]string{"type": "ephemeral"}},
		{Type: "text", Text: retrieved, CacheControl: map[string]string{"type": "ephemeral"}},
		// Dynamic suffix - not cached.
		{Type: "text", Text: userMsg},
	}
}
```

OpenAI's prompt cache is automatic above a token threshold; the same prefix-stability rule applies. Track `cache_read_input_tokens` (Anthropic) or `prompt_tokens_details.cached_tokens` (OpenAI) per request; alert when the cache hit ratio drops, since that signals an unintended prefix change.

## Structured output / constrained generation

Validation should be the second line of defense, not the first. In 2026 the right primary lever is constrained generation at the model boundary:

- **Anthropic**: tool use with a JSON schema returns structured tool input (no free-text JSON parsing).
- **OpenAI**: `response_format: {"type": "json_schema", "json_schema": {...}}` for guaranteed JSON conforming to schema.
- **Gemini**: structured-output mode with response schema.

Output validation - post-hoc JSON Schema check - remains a safety net for API failures, tool-use mode regressions, or providers that occasionally return free text inside a tool-use response. Keep the validator from the Idempotent Receiver section; remove the prompt-engineering "please return JSON" hack.

```go
// Pattern: Format Indicator + Message Translator at the model boundary.
// Constrained generation guarantees shape; validator is the safety net.
type ExtractRequest struct {
	Schema json.RawMessage // JSON Schema for the desired output.
}

func extract(ctx context.Context, req ExtractRequest, input string) (PlannedAction, error) {
	resp, err := client.Messages(ctx, openai.ChatRequest{
		ResponseFormat: &openai.ResponseFormat{
			Type:       "json_schema",
			JSONSchema: req.Schema,
		},
		Messages: []openai.Message{{Role: "user", Content: input}},
	})
	if err != nil { return PlannedAction{}, err }
	var out PlannedAction
	if err := json.Unmarshal(resp.Content, &out); err != nil {
		return PlannedAction{}, err // Should be unreachable; quarantine if seen.
	}
	return out, schema.Validate(out)
}
```

## Degradation modes

Treat the LLM as a degradable dependency, not a single critical path. When the provider returns sustained 5xx / 429 / 529 (Anthropic capacity), fall back rather than fail.

- **Smaller-model fallback**: Sonnet -> Haiku, GPT-4 -> GPT-4o-mini. Cheaper and usually still online when the larger model's capacity is exhausted.
- **Cached-response fallback**: return the last good cached answer with a `stale: true` marker so the client can show a banner.
- **Deterministic-logic fallback**: for narrow tasks (regex extraction, lookup tables, rule-based classifiers) keep a non-LLM code path warm.
- Wrap the LLM client in a circuit breaker; emit `llm.degraded=true` and `llm.fallback=<mode>` metrics so dashboards show the fallback ratio.

```go
// Pattern: Circuit Breaker + Fallback applied to the LLM dependency.
func (s *Service) Answer(ctx context.Context, q Query) (Answer, error) {
	if s.breaker.State() == circuit.Open {
		return s.fallback(ctx, q) // small model / cache / deterministic.
	}
	resp, err := s.primary.Call(ctx, q)
	if err != nil && isCapacity(err) {
		s.breaker.RecordFailure()
		s.metrics.Inc("llm.degraded", "mode", "fallback")
		return s.fallback(ctx, q)
	}
	s.breaker.RecordSuccess()
	return resp, err
}
```

A fallback path that is never exercised will be broken when you need it; include it in chaos drills and synthetic traffic.

## References

- Anthropic API streaming: https://docs.anthropic.com/en/api/messages-streaming
- Anthropic rate limits: https://docs.anthropic.com/en/api/rate-limits
- OpenAI rate limit best practices: https://platform.openai.com/docs/guides/rate-limits
- Temporal documentation: https://docs.temporal.io/
- AWS Step Functions error handling: https://docs.aws.amazon.com/step-functions/latest/dg/concepts-error-handling.html
