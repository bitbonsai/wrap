# wrap

Claude Code skill: end-of-session wrap-up. Markdown (SKILL.md) + bash (scripts/install-hook.sh), no build, no deps beyond jq-or-python3 for the hook installer.

Repo is the distribution: anything committed ships to users who clone it. Test by invoking `/wrap` in a session; test install-hook.sh by running it in a temp dir and inspecting `.claude/settings.json`.

## Gotchas

- `.plans/next.md` never exists mid-session: SessionStart hook cats it into context and renames to `next.prev.md` before first prompt. Read `next.prev.md` if needed again.
- `claude skill install X` isn't a command; CLI treats unknown subcommands as a prompt and silently starts a session. Check `claude --help` before documenting CLI invocations.
- `jq` not preinstalled on most Linux distros or macOS; install-hook.sh falls back to python3 for that reason. Keep both paths working.
- Hook matcher must be `startup|clear` (not resume/compact), or handover gets re-injected and consumed on session resume.
- Installed copy at `~/.claude/skills/wrap` is a git clone: update with `git pull`, never by copying files.
- Test install-hook.sh three ways: fresh dir, re-run (idempotency), merge into settings.json that already has other hooks and permissions.
