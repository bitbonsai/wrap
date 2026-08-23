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

export PI_CODING_AGENT_DIR="$tmp/pi"
mkdir -p "$tmp/proj/.plans"
echo handover > "$tmp/proj/.plans/next.md"

# queue-pi-handover.sh: no-op without any Pi integration
(cd "$tmp/proj" && "$repo/scripts/queue-pi-handover.sh" >/dev/null)
[ ! -f "$tmp/pi/wrap-next.json" ] || { echo "FAIL: queued without integration" >&2; exit 1; }

# queue-pi-handover.sh: detects legacy extension copy, queues
mkdir -p "$tmp/pi/extensions"
touch "$tmp/pi/extensions/wrap-handover.ts"
(cd "$tmp/proj" && "$repo/scripts/queue-pi-handover.sh" >/dev/null)
grep -q "$tmp/proj/.plans/next.md" "$tmp/pi/wrap-next.json"
rm -rf "$tmp/pi"

# queue-pi-handover.sh: detects a wrap package entry in settings
mkdir -p "$tmp/pi"
printf '{"packages": ["git:github.com/user/wrap@v1"]}\n' > "$tmp/pi/settings.json"
"$repo/scripts/queue-pi-handover.sh" --detect | grep -q "integration installed"
printf '{"packages": ["npm:wrapper"]}\n' > "$tmp/pi/settings.json"
"$repo/scripts/queue-pi-handover.sh" --detect | grep -q "not installed"
rm -rf "$tmp/pi"

# install-pi-extension.sh copy fallback (pi CLI hidden): installs, idempotent
env PATH="/usr/bin:/bin" "$repo/scripts/install-pi-extension.sh" >/dev/null
env PATH="/usr/bin:/bin" "$repo/scripts/install-pi-extension.sh" | grep -q "already installed"
cmp -s "$repo/extensions/wrap-handover.ts" "$tmp/pi/extensions/wrap-handover.ts"
rm -rf "$tmp/pi"

# install-pi-extension.sh package route (only when pi CLI is available):
# registers the skill dir as a package, removes the legacy copy, queue detects it
if command -v pi >/dev/null 2>&1; then
  mkdir -p "$tmp/pi/extensions"
  touch "$tmp/pi/extensions/wrap-handover.ts"
  "$repo/scripts/install-pi-extension.sh" | grep -q "package installed"
  [ ! -f "$tmp/pi/extensions/wrap-handover.ts" ] || { echo "FAIL: legacy copy not removed" >&2; exit 1; }
  grep -q "$repo" "$tmp/pi/settings.json"
  "$repo/scripts/queue-pi-handover.sh" --detect | grep -q "integration installed"
fi

echo OK
