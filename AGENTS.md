# wrap

Claude Code skill: end-of-session wrap-up. Markdown (SKILL.md) + bash (scripts/install-hook.sh), no build, no deps beyond jq-or-python3 for the hook installer.

Repo is the distribution: anything committed ships to users who clone it. Test by invoking `/wrap` in a session; run `scripts/test.sh` for the bundled scripts (shellcheck + idempotency + queue gating).

Release: bump `metadata.version` in SKILL.md, commit, annotated tag `v<same version>`, `git push && git push --tags`. README badge reads the tag.

## Gotchas

- `.plans/next.md` never exists mid-session: SessionStart hook cats it into context and renames to `next.prev.md` before first prompt. Read `next.prev.md` if needed again.
- `claude skill install X` isn't a command; CLI treats unknown subcommands as a prompt and silently starts a session. Check `claude --help` before documenting CLI invocations.
- `jq` not preinstalled on most Linux distros or macOS; install-hook.sh falls back to python3 for that reason. Keep both paths working.
- Hook matcher must be `startup|clear` (not resume/compact), or handover gets re-injected and consumed on session resume.
- `~/.claude/skills/wrap` → `~/.agents/skills/wrap` → this repo (symlink chain): the installed skill IS this working tree. No sync step; uncommitted edits are live in sessions immediately.
- README duplicates SKILL.md behavior (files, retention, hook, Pi): changing the flow means editing both, or they drift.
- Test install-hook.sh three ways: fresh dir, re-run (idempotency), merge into settings.json that already has other hooks and permissions.
- Every !`cmd` substitution in SKILL.md must exit 0: non-zero aborts the whole skill with "Shell command failed for pattern", and 2>/dev/null hides the reason. Guard with `|| echo fallback` (bit a user whose session cwd wasn't a git repo: git log exits 128).
