#!/usr/bin/env bash
# Register the Pi wrap integration. Prefers `pi install <skill dir>` (a pi
# package: skill + extension, no copy, updates with the repo); falls back to
# copying the extension file when the pi CLI isn't available. Idempotent.
set -euo pipefail

skill_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
config_dir=${PI_CODING_AGENT_DIR:-"$HOME/.pi/agent"}
target="$config_dir/extensions/wrap-handover.ts"

if command -v pi >/dev/null 2>&1; then
  pi install "$skill_dir" >/dev/null
  # Drop the legacy copy so the extension doesn't load twice.
  rm -f "$target"
  echo "Pi wrap package installed (skill + extension) from $skill_dir"
  exit 0
fi

mkdir -p "$(dirname -- "$target")"
if [ -f "$target" ] && cmp -s "$skill_dir/extensions/wrap-handover.ts" "$target"; then
  echo "Pi wrap extension already installed at $target"
  exit 0
fi

cp "$skill_dir/extensions/wrap-handover.ts" "$target"
echo "Pi wrap extension installed at $target"
