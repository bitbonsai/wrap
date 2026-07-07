#!/usr/bin/env bash
# Merge the wrap SessionStart hook into .claude/settings.json. Idempotent.
# Uses jq when available, falls back to python3.
set -euo pipefail

SETTINGS=".claude/settings.json"
HOOK_CMD='if [ -f .plans/next.md ]; then cat .plans/next.md && mv .plans/next.md .plans/next.prev.md; fi'

mkdir -p .claude
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

if command -v jq >/dev/null 2>&1; then
  if ! jq -e . "$SETTINGS" >/dev/null 2>&1; then
    echo "error: $SETTINGS is not valid JSON; fix it manually first" >&2
    exit 1
  fi
  if jq -e --arg cmd "$HOOK_CMD" \
    '.hooks.SessionStart[]?.hooks[]? | select(.command == $cmd)' \
    "$SETTINGS" >/dev/null 2>&1; then
    echo "wrap hook already installed in $SETTINGS"
    exit 0
  fi
  tmp=$(mktemp)
  jq --arg cmd "$HOOK_CMD" \
    '.hooks.SessionStart = ((.hooks.SessionStart // []) + [{
      matcher: "startup|clear",
      hooks: [{type: "command", command: $cmd}]
    }])' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
  echo "wrap hook installed in $SETTINGS (jq)"
elif command -v python3 >/dev/null 2>&1; then
  HOOK_CMD="$HOOK_CMD" SETTINGS="$SETTINGS" python3 - <<'PY'
import json, os, sys

settings_path = os.environ["SETTINGS"]
cmd = os.environ["HOOK_CMD"]

try:
    with open(settings_path) as f:
        settings = json.load(f)
except json.JSONDecodeError:
    sys.exit(f"error: {settings_path} is not valid JSON; fix it manually first")

entries = settings.setdefault("hooks", {}).setdefault("SessionStart", [])
for entry in entries:
    for hook in entry.get("hooks", []):
        if hook.get("command") == cmd:
            print(f"wrap hook already installed in {settings_path}")
            sys.exit(0)

entries.append({
    "matcher": "startup|clear",
    "hooks": [{"type": "command", "command": cmd}],
})

tmp = settings_path + ".tmp"
with open(tmp, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
os.replace(tmp, settings_path)
print(f"wrap hook installed in {settings_path} (python3)")
PY
else
  echo "error: needs jq or python3 (jq: brew install jq / apt install jq)" >&2
  exit 1
fi
