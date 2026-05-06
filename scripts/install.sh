#!/usr/bin/env bash
# Install the distributed-systems-patterns skill into every detected agent tool.
# Idempotent and safe: refuses to overwrite existing non-symlink targets.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_NAME="distributed-systems-patterns"
CANONICAL="$HOME/.agents/skills/$SKILL_NAME"
ALL=0
DRY_RUN=0

usage() {
    cat <<EOF
Usage: install.sh [--all] [--dry-run] [-h|--help]

Detects installed agent tools and creates symlinks pointing at this checkout.
Canonical location is ~/.agents/skills/$SKILL_NAME.

Options:
  --all      Install for every supported tool, even if its config dir is missing.
  --dry-run  Print what would happen without modifying the filesystem.
  -h, --help Print this help.

Supported: Claude Code, OpenCode, Codex (activation pointer).
For Cursor, see docs/cursor-setup.md (per-repo rule, not global).
EOF
}

for arg in "$@"; do
    case "$arg" in
        --all) ALL=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf '[WARN] unknown flag: %s\n' "$arg" >&2; usage; exit 2 ;;
    esac
done

log_ok()   { printf '[OK]   %s\n' "$1"; }
log_skip() { printf '[SKIP] %s\n' "$1"; }
log_warn() { printf '[WARN] %s\n' "$1" >&2; }
run()      { if (( DRY_RUN )); then printf '[DRY]  %s\n' "$*"; else "$@"; fi; }

# Resolve a symlink target portably (no readlink -f on macOS by default).
resolve_link() {
    [[ -L "$1" ]] && python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$1"
}

ensure_canonical() {
    if [[ -L "$CANONICAL" ]]; then
        local target; target="$(resolve_link "$CANONICAL")"
        if [[ "$target" == "$SKILL_DIR" ]]; then
            log_ok "canonical location already linked ($CANONICAL)"; return 0
        fi
        log_warn "canonical points to $target; remove manually to relink"; return 0
    fi
    if [[ -e "$CANONICAL" ]]; then
        log_warn "canonical exists and is not a symlink: $CANONICAL"
        log_warn "remove or move it manually, then re-run this installer"
        return 0
    fi
    run mkdir -p "$HOME/.agents/skills"
    run ln -s "$SKILL_DIR" "$CANONICAL"
    log_ok "linked canonical $CANONICAL -> repo"
}

# Generic symlink installer: link target to canonical skill dir (or any source).
link_to() {
    local label="$1" target="$2" source="${3:-$CANONICAL}"
    if [[ -L "$target" ]]; then
        local cur; cur="$(resolve_link "$target")"
        if [[ "$cur" == "$source" || "$cur" == "$SKILL_DIR" ]]; then
            log_ok "$label already linked"; return 0
        fi
        log_warn "$label points elsewhere ($cur); remove manually to relink"; return 0
    fi
    if [[ -e "$target" ]]; then
        log_warn "$label exists and is not a symlink: $target (skipping)"; return 0
    fi
    run mkdir -p "$(dirname "$target")"
    run ln -s "$source" "$target"
    log_ok "$label linked"
}

install_claude_code() {
    if [[ -d "$HOME/.claude" || $ALL -eq 1 ]]; then
        link_to "Claude Code" "$HOME/.claude/skills/$SKILL_NAME"
    else
        log_skip "Claude Code (no ~/.claude directory)"
    fi
}

install_opencode() {
    if [[ -d "$HOME/.config/opencode" || $ALL -eq 1 ]]; then
        link_to "OpenCode" "$HOME/.config/opencode/skills/$SKILL_NAME"
    else
        log_skip "OpenCode (no ~/.config/opencode directory)"
    fi
}

install_codex() {
    local agents_md="$HOME/.codex/AGENTS.md"
    local begin="# >>> $SKILL_NAME >>>"
    local end="# <<< $SKILL_NAME <<<"
    if [[ ! -d "$HOME/.codex" && $ALL -eq 0 ]]; then
        log_skip "Codex (no ~/.codex directory)"; return 0
    fi
    if [[ -f "$agents_md" ]] && grep -qF "$begin" "$agents_md" 2>/dev/null; then
        log_ok "Codex activation block already present"; return 0
    fi
    run mkdir -p "$HOME/.codex"
    if (( DRY_RUN )); then
        printf '[DRY]  append activation block to %s\n' "$agents_md"
    else
        {
            printf '\n%s\n' "$begin"
            printf 'Use the %s skill at %s/AGENTS.md\n' "$SKILL_NAME" "$CANONICAL"
            printf 'for distributed systems, messaging, resilience, workflow, and architecture work.\n'
            printf '%s\n' "$end"
        } >> "$agents_md"
    fi
    log_ok "Codex activation block appended to ~/.codex/AGENTS.md"
}

main() {
    printf 'Installing %s from %s\n' "$SKILL_NAME" "$SKILL_DIR"
    (( DRY_RUN )) && printf '(dry run; no filesystem changes)\n'
    ensure_canonical
    install_claude_code
    install_opencode
    install_codex
    log_skip "Cursor (per-repo rule; see docs/cursor-setup.md)"
    printf '\nDone. Verify with:\n  bash %s/scripts/validate_skill.sh\n' "$SKILL_DIR"
}

main
