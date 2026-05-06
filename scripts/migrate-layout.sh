#!/usr/bin/env bash
# migrate-layout.sh - migrate a distributed-systems-patterns project from
# the v0.2 scattered layout to the v0.3 per-feature folder layout.
#
# Run from your project root (NOT from the skill source).
#
# Usage:
#   bash scripts/migrate-layout.sh           # apply moves
#   bash scripts/migrate-layout.sh --dry-run # preview without moving
#   bash scripts/migrate-layout.sh --help

set -euo pipefail

DRY_RUN=0
case "${1:-}" in
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --dry-run) DRY_RUN=1 ;;
    "") ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
esac

USE_GIT=0
[[ -d .git ]] && command -v git >/dev/null 2>&1 && USE_GIT=1
shopt -s nullglob

mv_one() {
    local src=$1 dst=$2
    [[ -e "$src" ]] || { echo "[SKIP] missing: $src"; return; }
    [[ -e "$dst" ]] && { echo "[WARN] exists, refusing to overwrite: $dst"; return; }
    if (( DRY_RUN )); then echo "[OK]   (dry-run) $src -> $dst"; return; fi
    mkdir -p "$(dirname "$dst")"
    if (( USE_GIT )) && git ls-files --error-unmatch "$src" >/dev/null 2>&1; then
        git mv "$src" "$dst"
    else
        mv "$src" "$dst"
    fi
    echo "[OK]   $src -> $dst"
}

# Find which feature owns a channel by scanning per-feature READMEs (post-migration).
owner_for_channel() {
    local channel=$1 readme
    for readme in docs/features/*/README.md; do
        [[ -f "$readme" ]] && grep -Fq "$channel" "$readme" \
            && { basename "$(dirname "$readme")"; return 0; }
    done
    return 1
}

move_by_channel() {
    local kind=$1 src_dir=$2 dest_sub=$3 f base channel slug
    for f in "$src_dir"/*; do
        [[ -f "$f" ]] || continue
        base=$(basename "$f")
        channel=${base%.*}
        if slug=$(owner_for_channel "$channel"); then
            mv_one "$f" "docs/features/$slug/$dest_sub/$base"
        else
            echo "[WARN] no producer feature found for $kind $base; leaving at $f"
        fi
    done
    [[ -d "$src_dir" ]] && rmdir "$src_dir" 2>/dev/null || true
}

echo "== per-feature indexes =="
for r in docs/services/*/README.md; do
    slug=$(basename "$(dirname "$r")")
    mv_one "$r" "docs/features/$slug/README.md"
done
[[ -d docs/services ]] && rmdir docs/services/*/ docs/services 2>/dev/null || true

echo "== designs =="
for f in docs/designs/*-design.md; do
    base=$(basename "$f"); slug=${base%-design.md}
    mv_one "$f" "docs/features/$slug/design.md"
done
[[ -d docs/designs ]] && rmdir docs/designs 2>/dev/null || true

echo "== ADRs (defaulting to platform-wide; review manually) =="
for f in docs/adr/*.md; do mv_one "$f" "docs/system/adrs/$(basename "$f")"; done
[[ -d docs/adr ]] && rmdir docs/adr 2>/dev/null || true

echo "== contracts =="; move_by_channel contract docs/contracts contracts
echo "== schemas =="; move_by_channel schema schemas schemas
echo "== asyncapi ==";  move_by_channel asyncapi asyncapi asyncapi

echo "== runbooks (matching slug prefix to feature) =="
for f in docs/runbooks/*.md; do
    [[ -f "$f" ]] || continue
    base=$(basename "$f"); matched=""
    for feat in docs/features/*/; do
        [[ -d "$feat" ]] || continue
        slug=$(basename "$feat")
        if [[ "$base" == "$slug-"* || "$base" == *"-$slug-"* || "$base" == *"-$slug.md" ]]; then
            matched=$slug; break
        fi
    done
    if [[ -n "$matched" ]]; then
        mv_one "$f" "docs/features/$matched/runbooks/$base"
    else
        echo "[WARN] no feature slug matched in $base; leaving at $f"
    fi
done
[[ -d docs/runbooks ]] && rmdir docs/runbooks 2>/dev/null || true

echo "== launches (<slug>-<date>.md) =="
for f in docs/launches/*.md; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f" .md)
    if [[ "$name" =~ ^(.+)-([0-9]{4}-[0-9]{2}-[0-9]{2})$ ]]; then
        mv_one "$f" "docs/features/${BASH_REMATCH[1]}/launches/${BASH_REMATCH[2]}.md"
    else
        echo "[WARN] launch filename not <slug>-<date>.md form: $name.md; leaving"
    fi
done
[[ -d docs/launches ]] && rmdir docs/launches 2>/dev/null || true

cat <<'EOF'

migration done.

NOTE: ADRs were moved to docs/system/adrs/ as a safe default. Most ADRs
are actually feature-scoped and should move to docs/features/<slug>/adrs/.
Review each ADR and run `git mv docs/system/adrs/<file> docs/features/<slug>/adrs/<file>`
where appropriate. Renumber within each folder as needed.

If any [WARN] lines appeared, those files were NOT moved - handle by hand.
EOF
