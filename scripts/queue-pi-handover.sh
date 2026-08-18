#!/usr/bin/env bash
# Point Pi's next startup or /new session at the latest wrap handover.
# No-op when the Pi wrap extension isn't installed.
set -euo pipefail

config_dir=${PI_CODING_AGENT_DIR:-"$HOME/.pi/agent"}
if [ ! -f "$config_dir/extensions/wrap-handover.ts" ]; then
  echo "Pi wrap extension not installed; nothing queued"
  exit 0
fi

next=${1:-.plans/next.md}
if [ ! -f "$next" ]; then
  echo "error: handover not found: $next" >&2
  exit 1
fi

NEXT_PATH=$(cd -- "$(dirname -- "$next")" && pwd)/$(basename -- "$next")
POINTER_PATH="$config_dir/wrap-next.json"

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
