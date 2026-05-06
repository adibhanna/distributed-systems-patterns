#!/usr/bin/env bash
# Validate the distributed-systems-patterns skill.
# Uses only python3 and grep/awk so it runs in CI without Ruby or ripgrep.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail=0
ok()  { printf '%s %s\n' "✓" "$1"; }
bad() { printf '%s %s\n' "✗" "$1" >&2; fail=1; }

# 1. Frontmatter check on SKILL.md (name, description present, description < 1024 chars).
skill_name="$(python3 - <<'PY' 2>/dev/null || true
import re, sys
try: import yaml
except Exception: yaml = None
text = open("SKILL.md", encoding="utf-8").read()
m = re.match(r"^---\n(.*?)\n---", text, re.S)
if not m: print("ERR:no-frontmatter"); sys.exit(0)
front = m.group(1)
if yaml:
    try: data = yaml.safe_load(front) or {}
    except Exception as e: print(f"ERR:yaml:{e}"); sys.exit(0)
    name, desc = data.get("name"), data.get("description")
else:
    nm = re.search(r"(?m)^name:\s*(.+)$", front)
    dm = re.search(r"(?m)^description:\s*(.+)$", front)
    name = nm.group(1).strip() if nm else None
    desc = dm.group(1).strip() if dm else None
if not name: print("ERR:missing-name"); sys.exit(0)
if not desc: print("ERR:missing-description"); sys.exit(0)
if len(desc) >= 1024: print(f"ERR:description-too-long:{len(desc)}"); sys.exit(0)
print(f"OK:{name}")
PY
)"

case "$skill_name" in
    OK:*) ok "SKILL.md frontmatter (${skill_name#OK:})" ;;
    ERR:*) bad "SKILL.md frontmatter: ${skill_name#ERR:}" ;;
    *) bad "SKILL.md frontmatter: unable to parse" ;;
esac

# 2. Name consistency between SKILL.md and agents/openai.yaml.
if [[ "$skill_name" == OK:* ]]; then
    sname="${skill_name#OK:}"
    yaml_token="$(grep -Eo 'Use \$[A-Za-z0-9_-]+' agents/openai.yaml | head -n1 | sed 's/^Use \$//')"
    if [[ -z "$yaml_token" ]]; then
        bad "agents/openai.yaml: no \$<skill> token in default_prompt"
    elif [[ "$yaml_token" != "$sname" ]]; then
        bad "name mismatch: SKILL.md=$sname agents/openai.yaml=\$$yaml_token"
    else
        ok "name consistent across SKILL.md and agents/openai.yaml ($sname)"
    fi
fi

# 3. Local markdown link check (excluding code fences, http(s)/mailto/anchor links).
link_report="$(python3 - <<'PY'
import os, re
bad = []
for root, _, files in os.walk("."):
    if "/.git" in root: continue
    for fn in files:
        if not fn.endswith(".md"): continue
        path = os.path.join(root, fn)
        text = re.sub(r"```.*?```", "", open(path, encoding="utf-8").read(), flags=re.S)
        for link in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
            if link.startswith(("http://","https://","mailto:","#")): continue
            target = link.split("#",1)[0]
            if not target: continue
            resolved = os.path.normpath(os.path.join(os.path.dirname(path), target))
            if not os.path.exists(resolved):
                bad.append(f"{path}: {link}")
print("\n".join(bad))
PY
)"
if [[ -z "$link_report" ]]; then
    ok "local markdown links resolve"
else
    bad "broken local markdown links:"
    printf '%s\n' "$link_report" >&2
fi

# 4. Stale reference scan. Em-dashes and Unicode arrows are valid prose, not staleness.
# `reference/non-go-pointers.md` legitimately contains Python/Java/TS snippets and is excluded.
stale_pat='```python|consumer\.py|producer\.py|EIP_Summary|35-page|Spring Cloud Sleuth'
stale_hits="$(grep -rEn --include='*.md' --exclude-dir='.git' --exclude='non-go-pointers.md' "$stale_pat" . 2>/dev/null || true)"
if [[ -z "$stale_hits" ]]; then
    ok "stale reference scan clean"
else
    bad "stale references found:"
    printf '%s\n' "$stale_hits" >&2
fi

if (( fail == 0 )); then
    printf '\nskill validation ok\n'
    exit 0
fi
printf '\nskill validation failed\n' >&2
exit 1
