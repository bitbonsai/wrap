# wrap

Claude Code skill: end-of-session wrap-up. Markdown (SKILL.md) + bash (scripts/install-hook.sh), no build, no deps beyond jq-or-python3 for the hook installer.

Repo is the distribution: anything committed ships to users who clone it. Test by invoking `/wrap` in a session; run `scripts/test.sh` for the bundled scripts (shellcheck + idempotency + queue gating).

Release: bump `metadata.version` in SKILL.md AND `version` in package.json (keep in sync), commit, annotated tag `v<same version>`, `git push && git push --tags`. README badge reads the tag.

## Gotchas

- `.plans/next.md` never exists mid-session: SessionStart hook cats it into context and renames to `next.prev.md` before first prompt. Read `next.prev.md` if needed again.
- `claude skill install X` isn't a command; CLI treats unknown subcommands as a prompt and silently starts a session. Check `claude --help` before documenting CLI invocations.
- `jq` not preinstalled on most Linux distros or macOS; install-hook.sh falls back to python3 for that reason. Keep both paths working.
- Hook matcher must be `startup|clear` (not resume/compact), or handover gets re-injected and consumed on session resume.
- Installed skill may be an npx-managed clone (`~/.agents/skills/wrap`), not this working tree: uncommitted edits are NOT live until pushed + `npx skills update wrap`. For live dev, symlink instead: `rm -rf ~/.agents/skills/wrap && ln -s <repo> ~/.agents/skills/wrap`.
- README duplicates SKILL.md behavior (files, retention, hook, Pi): changing the flow means editing both, or they drift.
- Test install-hook.sh three ways: fresh dir, re-run (idempotency), merge into settings.json that already has other hooks and permissions.
- Every !`cmd` substitution in SKILL.md must exit 0: non-zero aborts the whole skill with "Shell command failed for pattern", and 2>/dev/null hides the reason. Guard with `|| echo fallback` (bit a user whose session cwd wasn't a git repo: git log exits 128).
- Subagent tests of wrap have no clean baseline: installed skill auto-triggers from available_skills even when the test prompt names no skill. Renaming inside ~/.claude/skills (wrap.disabled) still loads; park the symlink outside the dir for true A/B.
- Fixture-repo wrap runs leak real machine state: gotchas land in the caller's auto-memory and step 3.3 queues ~/.pi/agent/wrap-next.json at the fixture path. Delete both after test runs.
- Repo doubles as a pi package (package.json `pi` manifest: skill from root SKILL.md, extension from extensions/). Skill alone can't auto-inject handovers on pi: skills are prompt-only, session_start needs an extension. Claude hook in .claude/settings.json is invisible to pi.
- Pi CLI honors PI_CODING_AGENT_DIR for settings too, so test.sh can run a real `pi install` isolated. `pi -e <dir> -p "..."` loads a package for one print-mode run: cheap end-to-end check.
- `pi install <local path>` stores path RELATIVE to settings.json (`../../bit/wrap`). Match entries by suffix, not absolute compare; bit the settings filter once.
- pi dedupes a skill reachable via package AND skills dir at same resolved path: 1 skill, no warning. Unfiltered package entry safe alongside ~/.agents/skills symlink.
- skills CLI `-a` repeats per agent (`-a claude-code -a pi`); comma list read as one invalid agent name.
- Repo HAS committed `.plans/`; plain `ls` hides dotdirs. Read INDEX.md before writing, blind Write clobbered its Planned items once.
- SKILL.md description MUST stay a `>-` block scalar. Single-line description with inner ": " breaks skills.sh CLI ("YAML parse error: Nested mappings are not allowed in compact mappings") and `npx skills add` finds no skills. Verify with `npx -y skills add <repo-or-path> -l` after description edits.
