# Auto-handover hook: manual install

Fallback for when `scripts/install-hook.sh` can't run (no `jq`, unwritable settings). Merge this into the project's `.claude/settings.json`, preserving all existing keys and hooks:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear",
        "hooks": [
          {
            "type": "command",
            "command": "if [ -f .plans/next.md ]; then cat .plans/next.md && mv .plans/next.md .plans/next.prev.md; fi"
          }
        ]
      }
    ]
  }
}
```

Merge rules:

- If `hooks.SessionStart` already exists, append this entry to the array; don't replace it
- If an entry with this exact `command` already exists, do nothing
- Never drop existing keys (`permissions`, `env`, other hooks)
- Validate the result is parseable JSON before saving

What the hook does: on session start (new session or `/clear`, not resume/compact), it prints `.plans/next.md` into context, then moves the file to `.plans/next.prev.md`. That both consumes the handover (a stale one is never read twice) and keeps exactly one backup.
