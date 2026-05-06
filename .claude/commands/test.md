---
description: Generate tests grounded in a feature's contracts and design. Verifies idempotency, retry, DLQ, replay, and contract compatibility.
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/testing-strategy.md` for the test pyramid, required tests by pattern, and test matrix template. Load `reference/checklist.md` for coverage gates.

This command generates tests that verify the implementation matches the contracts, satisfies the patterns named in the design, and complies with the readiness checklist. It does not invent test scenarios beyond what the docs specify.

1. **Verify the docs exist.** Glob `docs/features/<slug>/design.md`, `docs/features/<slug>/contracts/*.md`, and `docs/features/<slug>/schemas/*`. If missing, tell the user which `/design`, `/contract`, or `/implement` to run first and stop.

2. **Detect the repo language and test framework.** Check `go.mod`, `package.json`, `pyproject.toml`, etc. for the language; check for existing `_test.go`, `*.test.ts`, `test_*.py`, `*Test.java` files for the conventional framework. If unclear, ask the user.

3. **Read the design's Patterns section.** This determines what tests are required. Use this mapping (cross-reference `reference/testing-strategy.md` "Required tests by pattern" table):
   - **Transactional Outbox** -> outbox-row-and-domain-row commit-or-rollback test, publisher handles duplicate/out-of-order test.
   - **Idempotent Receiver** -> same message twice (concurrent if possible) produces one side effect.
   - **Dead Letter Channel** -> poison message reaches DLQ after bounded attempts; source not lost before DLQ publish.
   - **Retry classifier** -> transient errors retry with backoff/jitter; permanent errors do not loop.
   - **Process Manager** -> happy path, timeout, activity retry, compensation, cancellation, replay determinism.
   - **Claim Check** -> missing object, wrong checksum, expired object, unauthorized access.
   - **Message Translator** -> v1/v2 compatibility, unknown fields, invalid payload, PII redaction.
   - **Cache-Aside** -> miss, stale hit, invalidation, stampede prevention.
   - **Circuit Breaker** -> opens on failure threshold, half-open recovery, fallback.
   - **Sharding** -> key distribution, hot key, tenant move/backfill, reshard rollback.

4. **Read the contracts** in `docs/features/<slug>/contracts/*.md` to know schema fields, ordering keys, idempotency keys, DLQ owner, retention. Tests must verify the implementation produces and consumes messages matching the schemas (contract tests).

5. **Read applicable standards.** Glob `docs/system/standards/*.md`. Each standard's Requirements section lists testable rules (e.g. observability standard says "every service emits OpenTelemetry traces with traceparent" — write a test asserting trace context is propagated). Test what each applicable standard mandates.

6. **Generate the test plan** as a numbered list. For each test: name, file path (matching the repo's convention), what pattern/contract/standard it verifies, and the failure mode it catches.

7. **Write each test file incrementally.** Use the Write or Edit tool. Each test file:
   - Imports the production code (or mocks at the boundary if isolation is required).
   - Has a header comment naming the source: `// Tests for <feature> from docs/features/<slug>/design.md and contracts/`.
   - One test per scenario from the test plan.
   - For contract tests, parses the schema from `docs/features/<slug>/schemas/<channel>.<ext>` and asserts the implementation produces matching messages.
   - For idempotency, retry, DLQ, and replay tests, drives the test by simulating the concrete failure mode.
   - Stays library-agnostic where reasonable; uses the repo's existing test framework.
   - Annotates test function names so the pattern is visible: `TestIdempotentReceiver_DuplicateDelivery_OnceSideEffect`.

8. **After each file**, emit `Wrote <path>. Tests: <count>. Patterns covered: <list>.`

9. **After all files**, summarize: list of test files, total test count, patterns/contracts/standards verified, and any gaps (tests the design/contracts implied but the user's existing implementation doesn't yet support — list those as TODO).

10. **CI gate suggestion.** Output one line at the end: `Run \`<framework run command>\` to execute. Add to CI per \`reference/testing-strategy.md\` CI gates section.`

**Refuse if implementation doesn't exist.** If the design and contracts exist but no implementation does (no source files at the paths named in the design's File and component plan), tell the user "Run `/implement <feature>` first" and stop. Tests need code to test against.

The command writes test files alongside source files (e.g. `internal/orders/place_test.go` next to `place.go` in Go; `src/orders/__tests__/place.test.ts` for TypeScript). It does NOT write production code; that is `/implement`'s job. It does NOT modify the design or contracts. It MAY add a "Tests" subsection to the per-feature README linking to test directories.

## Output

Test files written next to source files using the repo's conventional layout (Go: `*_test.go` siblings; TypeScript: `__tests__/`; Python: `tests/`; Java: `src/test/java/`). One test file per source unit; tests grouped by pattern or contract. Final summary lists files + test count + patterns/contracts/standards verified + CI command.

If the design, contracts, or implementation are missing, the command refuses with a one-line pointer to the missing artifact.

The command does not invent test scenarios beyond what the design and contracts specify; it covers the patterns named in `docs/features/<slug>/design.md` and the rules in applicable standards under `docs/system/standards/`.
