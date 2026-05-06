---
description: Implement a feature from its existing design + contracts + standards. Refuses to run without docs.
---

Invoke the `distributed-systems-patterns` skill.

Load `reference/go-examples.md` for boundary code patterns when the repo is Go, or `reference/non-go-pointers.md` for Java/TypeScript/Python equivalents. Load `reference/checklist.md` to verify the implementation against production gates.

This command translates existing architectural decisions into code. It does not invent patterns, pick libraries on the user's behalf, or invent boundaries. It refuses to run if the design and contracts for the named feature do not yet exist - those must be in place first.

1. **Verify the docs exist.** Glob `docs/features/<slug>/design.md` and `docs/features/<slug>/contracts/*.md`. If the design is missing, tell the user "Run `/design <feature>` first" and stop. If contracts are missing for channels named in the design's Boundary contracts section, tell the user "Run `/contract <channel>` for each channel in the design's Boundary contracts section" and stop.

2. **Detect the repo language.** Check `go.mod`, `package.json`, `pyproject.toml`, `pom.xml`, `Cargo.toml`. If unclear, ask the user one question: "What language is the implementation in?" Default to language-agnostic pseudocode if no language is detectable and the user does not answer.

3. **Read the design's File and component plan section.** This lists every source file, migration, and IaC file the implementation will touch. Use this list as the implementation plan; do not invent files outside it.

4. **Read the design's Patterns and Boundary contracts sections.** These name the patterns to enforce (Outbox, Idempotent Receiver, Process Manager, etc.) and the conceptual boundary contracts (channel names, ordering keys, idempotency keys, retention, DLQ owner, compatibility mode).

5. **Read the contract files** in `docs/features/<slug>/contracts/*.md`. For each contract, read the matching schema (`docs/features/<slug>/schemas/<channel>.<ext>`) and AsyncAPI spec (`docs/features/<slug>/asyncapi/<channel>.yaml`). The implementation must produce/consume CloudEvents matching these schemas.

6. **Read applicable standards.** Glob `docs/system/standards/*.md`. Each standard with `Status: Active` or `Status: Draft` applies; the code must satisfy its Requirements section. Load the `## Shared references` section of `docs/features/<slug>/README.md` to see which standards the feature has explicitly opted into.

7. **Read the per-feature README** for ownership, tier, and system concerns context.

8. **Generate the implementation plan.** Output a numbered list of files to create, in dependency order (migrations before source files; schemas before producers; producers before consumers). For each file, name: the path (from the design's plan), the patterns it implements, the standards it satisfies, and any tests needed (the user can run `/test` afterward).

9. **Implement files incrementally.** For each file in the plan:
   - Use the Write or Edit tool to create the file.
   - Add a header comment at the top of the file noting the source: `// Pattern: <Pattern Name>; from docs/features/<slug>/design.md`. Use the appropriate comment syntax for other languages.
   - Annotate pattern boundaries inside the file with `// Pattern: ...` comments at the spot where the pattern is enforced (the outbox INSERT, the dedup check, the retry classifier, the ack/commit ordering). One comment per boundary, not every line.
   - Use library categories named in the design unless the user has explicitly picked a package; in that case use the picked package.
   - After each file, emit a one-line confirmation: `Wrote <path>. Patterns: <list>. Standards: <list>.`
   - Stop and ask before generating the next file if the user wants to interrupt or adjust.

10. **After all files are written**, summarize: list of files created, patterns implemented, standards satisfied, tests recommended (for the user to run `/test <feature>`). Update the per-feature README's `## Artifacts` section if a new `Implementation` subsection makes sense (link to a top-level `src/` or `internal/` directory). Update `docs/system/catalog.md` `Last reviewed` date.

The command writes source files at the paths named in the design's File and component plan. It does NOT write tests; that is `/test`'s job. It does NOT update `docs/features/<slug>/design.md` or any architectural artifact. It MAY add an `Implementation` subsection to the per-feature README's Artifacts section linking to the src/ paths.

**Refuse to extend the design.** If the user's prompt asks for a pattern not in the design, refuse and tell them to update the design first via `/design <feature> --update` or a regular prompt that revises the design doc.

Do not repeat the patterns themselves; reference SKILL.md and the catalog for definitions.

## Output

Files written under the paths named in `docs/features/<slug>/design.md`'s **File and component plan** section. The command emits one confirmation per file written. Final summary lists files + patterns + standards + recommended next step (`/test <feature>` to generate verifying tests).

If the design or contracts are missing, the command refuses with a one-line pointer to the missing doc.

If the user's prompt asks for code beyond what the design specifies, the command refuses and tells the user to update the design first.
