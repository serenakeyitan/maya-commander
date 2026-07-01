#!/usr/bin/env bash
# COMMANDER — install the local client (CLI + skill + Stop hook) on the owner's machine.
#
# This is the ONE-TIME setup for "Maya as voice commander for your background coding agents".
# It is idempotent and makes NO network calls. Path B: nothing here ever touches Anthropic creds.
#
# What it does:
#   1. installs the `maya` CLI to ~/.local/bin (or $MAYA_BIN_DIR)
#   2. installs the maya-discuss skill to ~/.claude/skills/maya-discuss
#   3. installs the Stop-hook script to ~/.claude/hooks/maya_stop_gate.py
#   4. registers the Stop hook in ~/.claude/settings.json (APPENDS — never clobbers existing hooks)
#
# It does NOT enable the hook. The hook is a no-op until you `touch ~/.maya/commander_hook_enabled`
# — the deliberate GO/NO-GO gate: measure the live trigger rate first, then enable.
#
# After install: it AUTO-RUNS `maya connect` for you (prints a 6-digit code) — no restart, no second
# command. You call Maya, pass your PIN, then TYPE those six digits on your phone keypad and you're
# linked. (Set MAYA_SKIP_CONNECT=1 to skip the auto-connect, e.g. for an unattended/CI install.)
# 🔴 Never set ANTHROPIC_API_KEY in your shell — it breaks the $0/subscription model.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
BIN_DIR="${MAYA_BIN_DIR:-$HOME/.local/bin}"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"

# LAYOUT-AGNOSTIC source resolution: this SAME installer runs from two repo shapes —
#   • the PUBLIC client repo (flat): ./maya, ./maya_stop_gate.py, ./skills/<name>/SKILL.md
#   • the PRIVATE source repo:       ./scripts/maya (one up), ./commander/<name>/SKILL.md (alongside)
# Probe both so the agent-mediated `git clone … && bash install.sh` works no matter which it cloned.
# NOTE: _find itself errors + exits on a total miss (instead of returning empty), because under
# `set -euo pipefail` a nonzero command-substitution would abort the assignment line BEFORE any later
# validation loop could print a diagnostic — the friendly error has to live INSIDE _find. This also
# avoids the bash-only ${!v} indirection (would break under dash).
_find() {  # _find <label> <candidates...> → echoes the first existing path; errors + exits if none
  local label="$1"; shift
  local c
  for c in "$@"; do [ -e "$c" ] && { printf '%s\n' "$c"; return 0; }; done
  echo "✗ install.sh: could not locate $label under $HERE — unexpected repo layout. Aborting." >&2
  exit 1
}
CLI_SRC="$(_find "the maya CLI" "$HERE/maya" "$REPO/scripts/maya")"
HOOK_SRC="$(_find "the Stop hook" "$HERE/maya_stop_gate.py" "$REPO/commander/maya_stop_gate.py")"
CONNECT_SKILL_SRC="$(_find "the maya-connect skill" "$HERE/skills/maya-connect/SKILL.md" "$HERE/maya-connect/SKILL.md")"
DISCUSS_SKILL_SRC="$(_find "the maya-discuss skill" "$HERE/skills/maya-discuss/SKILL.md" "$HERE/maya-discuss/SKILL.md")"

echo "Installing the maya CLI → $BIN_DIR/maya"
mkdir -p "$BIN_DIR"
cp "$CLI_SRC" "$BIN_DIR/maya"
chmod +x "$BIN_DIR/maya"

echo "Installing the maya-connect skill → $SKILLS_DIR/maya-connect"
mkdir -p "$SKILLS_DIR/maya-connect"
cp "$CONNECT_SKILL_SRC" "$SKILLS_DIR/maya-connect/SKILL.md"

echo "Installing the maya-discuss skill → $SKILLS_DIR/maya-discuss"
mkdir -p "$SKILLS_DIR/maya-discuss"
cp "$DISCUSS_SKILL_SRC" "$SKILLS_DIR/maya-discuss/SKILL.md"

echo "Installing the Stop hook → $HOOKS_DIR/maya_stop_gate.py"
mkdir -p "$HOOKS_DIR"
cp "$HOOK_SRC" "$HOOKS_DIR/maya_stop_gate.py"
chmod +x "$HOOKS_DIR/maya_stop_gate.py"

echo "Registering the Stop hook in $SETTINGS (append-only)…"
python3 - "$SETTINGS" "$HOOKS_DIR/maya_stop_gate.py" <<'PY'
import json, os, sys
settings_path, hook_path = sys.argv[1], sys.argv[2]
cmd = f"python3 {hook_path}"
try:
    with open(settings_path, encoding="utf-8") as fh:
        s = json.load(fh)
except (OSError, ValueError):
    s = {}
# Coerce non-object JSON (null / [] / a bare string|number is valid JSON but not a settings object)
# so setdefault can't AttributeError and abort the install with a partial state + raw traceback.
if not isinstance(s, dict):
    s = {}
hooks = s.get("hooks")
if not isinstance(hooks, dict):
    hooks = {}
    s["hooks"] = hooks
stop = hooks.get("Stop")
if not isinstance(stop, list):
    stop = []
    hooks["Stop"] = stop
# Idempotent: skip if our command is already registered anywhere in the Stop array.
already = any(
    h.get("command") == cmd
    for group in stop if isinstance(group, dict)
    for h in group.get("hooks", []) if isinstance(h, dict)
)
if already:
    print("  already registered — no change")
else:
    stop.append({"hooks": [{"type": "command", "command": cmd, "timeout": 5}]})
    os.makedirs(os.path.dirname(settings_path), exist_ok=True)
    with open(settings_path, "w", encoding="utf-8") as fh:
        json.dump(s, fh, indent=2)
    print("  appended (existing hooks preserved)")
PY

# ── PATH: make `maya` runnable from a plain shell without a manual edit. ──────────────────────────
# The CLI is a standalone binary (no skills needed to run `maya connect`), so we do NOT require a
# Claude Code restart here — restart only matters for the SKILLS to appear, which the connect step
# below does not use. We just make sure BIN_DIR is reachable now and in future shells.
case ":${PATH}:" in
  *":${BIN_DIR}:"*) : ;;  # already on PATH
  *)
    export PATH="${BIN_DIR}:${PATH}"  # this process (so the connect step below works immediately)
    # Persist for future shells — append to whichever rc the user's shell reads, idempotently.
    _rc=""
    case "${SHELL:-}" in
      *zsh)  _rc="$HOME/.zshrc" ;;
      *bash) _rc="$HOME/.bashrc" ;;
    esac
    if [ -n "$_rc" ]; then
      # Idempotency keyed on THIS bin dir (not just the marker), so re-installing to a different
      # MAYA_BIN_DIR still appends the new dir instead of being suppressed by the first install's line.
      _line="export PATH=\"$BIN_DIR:\$PATH\"  # added by maya-commander install"
      grep -qsF "$BIN_DIR:\$PATH\"  # added by maya-commander install" "$_rc" 2>/dev/null \
        || printf '\n%s\n' "$_line" >> "$_rc"
    fi
    ;;
esac

echo
echo "✓ Installed (CLI + skills + Stop hook). The hook is INSTALLED BUT DISABLED — it does nothing"
echo "  until you measure the trigger rate and opt in: touch ~/.maya/commander_hook_enabled"
echo "  🔴 Do NOT set ANTHROPIC_API_KEY (breaks the \$0/your-own-subscription model)."
echo

# ── AUTO-CHAIN INTO PAIRING: no second command, no restart. ───────────────────────────────────────
# The whole point of the "easiest install" design: the user typed one fuzzy sentence to their agent;
# they should NOT then have to remember/run `maya connect` themselves. So we run it for them, by
# ABSOLUTE PATH (so it works even if PATH didn't refresh), and the 6-digit code prints right here.
# The user TYPES those six digits on their phone keypad during the live call — the only human step.
echo "─────────────────────────────────────────────────────────────────"
echo " One last step: call Maya, pass your PIN, then TYPE the six digits below on your phone keypad."
echo "─────────────────────────────────────────────────────────────────"
if [ "${MAYA_SKIP_CONNECT:-}" = "1" ]; then
  echo "(MAYA_SKIP_CONNECT=1 — skipping auto-connect; run \`maya connect\` when ready.)"
else
  "$BIN_DIR/maya" connect --wait || {
    echo
    echo "If that didn't print a code, run it yourself once your shell is refreshed:  maya connect --wait"
  }
fi
