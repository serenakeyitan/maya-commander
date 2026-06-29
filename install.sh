#!/usr/bin/env bash
# maya-commander installer — installs the CLI + skill + Stop hook for "Maya as voice commander".
#
# Read this whole file before running it. It is idempotent, makes only the GitHub fetches noted
# below (from THIS public repo), and never touches your Anthropic credentials.
#
# What it does:
#   1. installs the `maya` CLI to ~/.local/bin (or $MAYA_BIN_DIR)
#   2. installs the maya-discuss skill to ~/.claude/skills/maya-discuss
#   3. installs the Stop-hook script to ~/.claude/hooks/maya_stop_gate.py
#   4. registers the Stop hook in ~/.claude/settings.json (APPENDS — never clobbers existing hooks)
#
# It does NOT enable the hook. The hook is a no-op until you `touch ~/.maya/commander_hook_enabled`
# — the deliberate go/no-go gate: verify it works first, then enable.
#
# Run it from a clone of this repo (uses the local files), or standalone (fetches the files from
# THIS repo's raw URLs over HTTPS). After install: restart Claude Code once, then `maya pair <code>`.
# 🔴 Never set ANTHROPIC_API_KEY in your shell — it breaks the $0/subscription model.
set -euo pipefail

RAW="${MAYA_RAW_BASE:-https://raw.githubusercontent.com/serenakeyitan/maya-commander/main}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
BIN_DIR="${MAYA_BIN_DIR:-$HOME/.local/bin}"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"

# fetch <relative-path> <dest> : copy from the local clone if present, else curl from this repo.
fetch() {
  local rel="$1" dest="$2"
  if [ -n "$HERE" ] && [ -f "$HERE/$rel" ]; then
    cp "$HERE/$rel" "$dest"
  else
    curl -fsSL "$RAW/$rel" -o "$dest"
  fi
}

echo "Installing the maya CLI -> $BIN_DIR/maya"
mkdir -p "$BIN_DIR"
fetch "maya" "$BIN_DIR/maya"
chmod +x "$BIN_DIR/maya"

echo "Installing the maya-discuss skill -> $SKILLS_DIR/maya-discuss"
mkdir -p "$SKILLS_DIR/maya-discuss"
fetch "skills/maya-discuss/SKILL.md" "$SKILLS_DIR/maya-discuss/SKILL.md"

echo "Installing the Stop hook -> $HOOKS_DIR/maya_stop_gate.py"
mkdir -p "$HOOKS_DIR"
fetch "maya_stop_gate.py" "$HOOKS_DIR/maya_stop_gate.py"
chmod +x "$HOOKS_DIR/maya_stop_gate.py"

echo "Registering the Stop hook in $SETTINGS (append-only)..."
python3 - "$SETTINGS" "$HOOKS_DIR/maya_stop_gate.py" <<'PY'
import json, os, sys
settings_path, hook_path = sys.argv[1], sys.argv[2]
cmd = f"python3 {hook_path}"
try:
    with open(settings_path, encoding="utf-8") as fh:
        s = json.load(fh)
except (OSError, ValueError):
    s = {}
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
already = any(
    h.get("command") == cmd
    for group in stop if isinstance(group, dict)
    for h in group.get("hooks", []) if isinstance(h, dict)
)
if already:
    print("  already registered - no change")
else:
    stop.append({"hooks": [{"type": "command", "command": cmd, "timeout": 5}]})
    os.makedirs(os.path.dirname(settings_path), exist_ok=True)
    with open(settings_path, "w", encoding="utf-8") as fh:
        json.dump(s, fh, indent=2)
    print("  appended (existing hooks preserved)")
PY

echo
echo "Installed. Next:"
echo "  1. Make sure $BIN_DIR is on your PATH."
echo "  2. Restart Claude Code once (new top-level skills dir)."
echo "  3. Pair with the code Maya texted you:  maya pair <code>"
echo "  4. The Stop hook is INSTALLED BUT DISABLED. When ready, measure with 'maya trigger-rate',"
echo "     then enable: touch ~/.maya/commander_hook_enabled"
echo "  Do NOT set ANTHROPIC_API_KEY (breaks \$0/subscription)."
