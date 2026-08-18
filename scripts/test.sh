#!/usr/bin/env bash
# Smoke test for bundled scripts. Run from anywhere: scripts/test.sh
set -euo pipefail

repo=$(cd -- "$(dirname -- "$0")/.." && pwd)

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$repo"/scripts/*.sh
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# install-hook.sh: creates settings, idempotent, valid JSON, exactly one entry
(cd "$tmp" && "$repo/scripts/install-hook.sh" >/dev/null && "$repo/scripts/install-hook.sh" >/dev/null)
python3 - "$tmp/.claude/settings.json" <<'PY'
import json, sys
settings = json.load(open(sys.argv[1]))
entries = settings["hooks"]["SessionStart"]
assert len(entries) == 1, f"expected 1 hook entry, got {len(entries)}"
assert "next.md" in entries[0]["hooks"][0]["command"]
PY

# queue-pi-handover.sh: no-op without extension, queues with it
export PI_CODING_AGENT_DIR="$tmp/pi"
mkdir -p "$tmp/proj/.plans"
echo handover > "$tmp/proj/.plans/next.md"
(cd "$tmp/proj" && "$repo/scripts/queue-pi-handover.sh" >/dev/null)
[ ! -f "$tmp/pi/wrap-next.json" ] || { echo "FAIL: queued without extension" >&2; exit 1; }
mkdir -p "$tmp/pi/extensions"
touch "$tmp/pi/extensions/wrap-handover.ts"
(cd "$tmp/proj" && "$repo/scripts/queue-pi-handover.sh" >/dev/null)
grep -q "$tmp/proj/.plans/next.md" "$tmp/pi/wrap-next.json"

# install-pi-extension.sh: installs, idempotent
"$repo/scripts/install-pi-extension.sh" >/dev/null
"$repo/scripts/install-pi-extension.sh" | grep -q "already installed"
cmp -s "$repo/assets/pi-wrap-handover.ts" "$tmp/pi/extensions/wrap-handover.ts"

echo OK
