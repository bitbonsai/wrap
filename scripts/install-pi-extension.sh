#!/usr/bin/env bash
# Install the global Pi extension that consumes queued wrap handovers. Idempotent.
set -euo pipefail

skill_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
config_dir=${PI_CODING_AGENT_DIR:-"$HOME/.pi/agent"}
target="$config_dir/extensions/wrap-handover.ts"

mkdir -p "$(dirname -- "$target")"
if [ -f "$target" ] && cmp -s "$skill_dir/assets/pi-wrap-handover.ts" "$target"; then
  echo "Pi wrap extension already installed at $target"
  exit 0
fi

cp "$skill_dir/assets/pi-wrap-handover.ts" "$target"
echo "Pi wrap extension installed at $target"
