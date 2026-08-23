#!/usr/bin/env bash
# Point Pi's next startup or /new session at the latest wrap handover.
# No-op when the Pi wrap integration isn't installed.
# `queue-pi-handover.sh --detect` only reports installed/not-installed.
set -euo pipefail

config_dir=${PI_CODING_AGENT_DIR:-"$HOME/.pi/agent"}

pi_installed() {
  # Legacy global copy, or a project-local extension.
  [ -f "$config_dir/extensions/wrap-handover.ts" ] && return 0
  [ -f ".pi/extensions/wrap-handover.ts" ] && return 0
  # Package install: a wrap entry in the settings packages array.
  local settings="$config_dir/settings.json"
  [ -f "$settings" ] || return 1
  if command -v jq >/dev/null 2>&1; then
    jq -e '[.packages // [] | .[] | if type == "object" then .source else . end
            | select(type == "string" and test("(^|[/:])wrap($|@)"))] | length > 0' \
      "$settings" >/dev/null 2>&1
  elif command -v python3 >/dev/null 2>&1; then
    SETTINGS="$settings" python3 - <<'PY'
import json, os, re, sys

with open(os.environ["SETTINGS"]) as f:
    settings = json.load(f)
for entry in settings.get("packages", []):
    source = entry.get("source") if isinstance(entry, dict) else entry
    if isinstance(source, str) and re.search(r"(^|[/:])wrap($|@)", source):
        sys.exit(0)
sys.exit(1)
PY
  else
    return 1
  fi
}

if [ "${1:-}" = "--detect" ]; then
  if pi_installed; then echo "Pi wrap integration installed"; else echo "Pi wrap integration not installed"; fi
  exit 0
fi

if ! pi_installed; then
  echo "Pi wrap integration not installed; nothing queued"
  exit 0
fi

next=${1:-.plans/next.md}
if [ ! -f "$next" ]; then
  echo "error: handover not found: $next" >&2
  exit 1
fi

NEXT_PATH=$(cd -- "$(dirname -- "$next")" && pwd)/$(basename -- "$next")
POINTER_PATH="$config_dir/wrap-next.json"
mkdir -p "$config_dir"

if command -v jq >/dev/null 2>&1; then
  tmp="$POINTER_PATH.tmp"
  jq -n --arg path "$NEXT_PATH" '{path: $path}' > "$tmp"
  mv "$tmp" "$POINTER_PATH"
elif command -v python3 >/dev/null 2>&1; then
  export NEXT_PATH POINTER_PATH
  python3 - <<'PY'
import json, os

path = os.environ["POINTER_PATH"]
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump({"path": os.environ["NEXT_PATH"]}, f)
    f.write("\n")
os.replace(tmp, path)
PY
else
  echo "error: needs jq or python3" >&2
  exit 1
fi

echo "Pi wrap handover queued from $NEXT_PATH"
