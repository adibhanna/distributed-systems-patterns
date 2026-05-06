#!/usr/bin/env bash
# Skeleton evaluation harness for the distributed-systems-patterns skill.
# Run via: ./scripts/eval.sh
#
# Reads reference/evaluation-prompts.md, extracts each named prompt's
# "Expected:" summary, and prints them as a checklist for manual review.
#
# Wiring this into automated grading (future maintainer notes):
#   1. Read each prompt block (delimited by ## headings) from the file.
#   2. POST the prompt text to your Anthropic-style /v1/messages endpoint
#      with the skill loaded in the system context.
#   3. Capture the response and assert it contains each pattern name from
#      the matching "Expected:" line. A simple substring match per term
#      is usually sufficient; for stricter grading, ask another model
#      to score the response against the expected behavior.
#   4. Aggregate pass/fail counts and exit non-zero if any prompt failed.
# This skeleton is dependency-free (no curl/jq) so CI can rely on it.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

src="reference/evaluation-prompts.md"
if [[ ! -f "$src" ]]; then
    printf '%s missing — nothing to evaluate\n' "$src" >&2
    exit 1
fi

awk '
    /^## / {
        if (name != "" && expected != "") {
            printf("[%s] :: %s\n", slug, expected)
        }
        name = substr($0, 4)
        slug = tolower(name)
        gsub(/[^a-z0-9]+/, "-", slug)
        sub(/^-/, "", slug); sub(/-$/, "", slug)
        expected = ""
        next
    }
    /^Expected:/ {
        sub(/^Expected:[[:space:]]*/, "")
        expected = $0
    }
    END {
        if (name != "" && expected != "") {
            printf("[%s] :: %s\n", slug, expected)
        }
    }
' "$src"
