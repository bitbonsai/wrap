#!/usr/bin/env bash
# Point Pi's next startup or /new session at the latest wrap handover.
set -euo pipefail

next=${1:-.plans/next.md}
if [ ! -f "$next" ]; then
  echo "error: handover not found: $next" >&2
  exit 1
fi

config_dir=${PI_CODING_AGENT_DIR:-"$HOME/.pi/agent"}
mkdir -p "$config_dir"
NEXT_PATH=$(cd -- "$(dirname -- "$next")" && pwd)/$(basename -- "$next")
POINTER_PATH="$config_dir/wrap-next.json"
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

echo "Pi wrap handover queued from $NEXT_PATH"
