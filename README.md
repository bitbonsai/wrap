<div align="center">
	<br>
	<img width="137" height="137" src="icon.svg" alt="Wrap">
	<br>
	<br>
	<h1>wrap</h1>
	<p>End-of-session wrap-up for <a href="https://github.com/anthropics/claude-code">Claude Code</a>. Extract gotchas, save learnings, reset with confidence.</p>
	<p><a href="https://github.com/bitbonsai/wrap/releases"><img src="https://img.shields.io/github/v/tag/bitbonsai/wrap?label=version" alt="version"></a> <a href="https://docs.tessl.io/improving-your-skills/reviewing-skills"><img src="https://img.shields.io/badge/tessl_review-99%25-brightgreen" alt="tessl review 99%"></a></p>
	<br>
	<br>
</div>

> Most session logs are noise. "Shipped v3.57.4" is in git. "CSS is 18KB now" is in the code. The only thing worth persisting is what went **wrong** and what the user **prefers**, because those are invisible to future agents reading the codebase.

## Install

### skills.sh

```bash
npx skills add github:bitbonsai/wrap
```

You can use [skills.sh](https://skills.sh) to add this skill globally.

### Claude Code

There is no `claude skill install` command. Clone into your skills directory instead:

```bash
# global (all projects)
git clone https://github.com/bitbonsai/wrap.git ~/.claude/skills/wrap

# or per project
git clone https://github.com/bitbonsai/wrap.git .claude/skills/wrap
```

### pi.dev

```bash
pi install git:github.com/bitbonsai/wrap
```

### OpenCode

OpenCode is compatible with Claude skills. Clone into `.claude/skills/`:

```bash
git clone https://github.com/bitbonsai/wrap.git .claude/skills/wrap
```

## Usage

Say any of:

- "wrap"
- "wrap up"
- "let's wrap"
- "save learnings"
- "end of session"
- "I'm done for now"

## What it does

Three steps:

1. **Extract & route**: pulls gotchas from the session (things that broke, wrong assumptions, counterintuitive behavior) and writes each one to exactly one home: project facts go to `AGENTS.md`, personal preferences and machine-specific quirks go to Claude's auto-memory.
2. **Sync**: fixes contradictions the session created: a README that now documents the wrong command, a shipped item still listed as active in `.plans/INDEX.md`, a memory entry about a bug that got fixed.
3. **Handover**: writes a self-contained continuation prompt to `.plans/next.md` so the next session picks up exactly where this one left off.

Setup is a side effect, not a questionnaire. Missing files are created silently and noted in the summary; git is the review. The only question wrap ever asks is whether to install the auto-handover hook, once per project, and it remembers if you decline.

## What it does NOT record

- What was shipped (git log has this)
- Feature descriptions (docs have this)
- Rollout timelines
- Anything derivable from reading the code

## The files

### `AGENTS.md`

The one committed context file: a brief description of the repo plus a running gotcha list. It travels with `git clone`, so learnings work on every machine and for every teammate, and both Claude Code and OpenCode load it automatically.

```markdown
# MyProject

Payment dashboard. Next.js, deployed on Vercel.

## Gotchas

- Don't use `find -delete`, it deletes directories matching the pattern too
- `bun run` doesn't pass env vars the same way as `npm run`
- Always run `terraform plan` before `apply`, the staging state drifts fast
```

**Why one file:** a gotcha in a committed file is portable memory. A gotcha only in local auto-memory is stuck on one machine, in one harness. If your project uses `CLAUDE.md` for this role, wrap updates that instead. If the gotcha list outgrows a page, wrap prunes it (drops lines that got fixed, became derivable from the code, or never recurred) rather than splitting it into a second file.

Personal preferences ("be terse", "never force-push") and machine-specific facts (local auth quirks) go to Claude's auto-memory instead, they don't belong in the repo.

### `.plans/INDEX.md`

A lightweight tracker with three sections:

```markdown
## Active
- [ ] Add dark mode toggle (waiting on design tokens)

## Planned
- [ ] Migrate from Stripe Checkout to Payment Elements

## Recently shipped
- [x] v2.4.0: Team billing + seat management
```

**Why it helps:** agents lose track of what's in progress versus done. A simple index prevents "did we already do this?" without a full project management tool.

Recently shipped keeps the last 5 items; older lines are dropped (git history keeps them). Plan files are named `YYYY-MM-DD-slug.md`; when one ships or is abandoned, wrap moves it to `.plans/.archive/`, so `.plans/` root only holds current work.

### `.plans/next.md`

The handover prompt from the last wrap, written automatically at the end of each session:

```markdown
Branch: feature/oauth-migration (PR #42)

What shipped this session: token refresh in src/auth/refresh.ts, e2e tests

Status: pushed, tests green, typecheck clean.

What still needs doing:
1. Wire refresh into the session middleware
2. Remove the legacy JWT path

Known gaps / follow-up:
- Rate limiting on the refresh endpoint is stubbed
```

**Why it helps:** the next agent picks up exactly where the last session left off. No re-explaining, no digging through git log.

With the optional `SessionStart` hook (wrap offers to install it, once), `/clear` alone is enough: the hook injects `next.md` into the new session and moves it to `next.prev.md`, so a stale handover is never read twice and you always keep one backup. Without the hook, tell the new agent to read `.plans/next.md`.

`next.md` and `next.prev.md` are transient per-machine state; wrap adds them to `.gitignore` automatically.

wrap installs the hook with a bundled script (`scripts/install-hook.sh`, uses `jq` or `python3`, whichever is available) that merges into `.claude/settings.json` without touching your existing settings. What it adds:

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

### Pi support

wrap also works with Pi (`@earendil-works/pi-coding-agent`). It offers to install a global extension (`scripts/install-pi-extension.sh` copies `assets/pi-wrap-handover.ts` to `~/.pi/agent/extensions/`) that injects the handover on startup and `/new`. Each wrap queues the handover path in `~/.pi/agent/wrap-next.json` (`scripts/queue-pi-handover.sh`), so Pi finds it even when the new session starts in a subdirectory of the wrapped project. A pointer left by a different project is ignored and restored, and a stale pointer (handover already consumed by the Claude hook) is cleaned up.

## Migrating from older wrap versions

Earlier versions (v1.x) maintained `globalcontext.md` and `agent-learnings.md` as separate files. On your next wrap, the skill folds their non-derivable content into `AGENTS.md` and deletes them, noting the fold in the closing summary (git is the review; object once and it never folds in that repo again). Orientation facts an agent can derive from the repo (stack, commands in package.json) are dropped rather than migrated.

To stay on the old design, pin the tag: `git -C ~/.claude/skills/wrap checkout v1.0.0`.

## Thanks

[@cntlsn](https://github.com/cntlsn) for reporting and diagnosing the non-git-cwd crash fixed in v2.4.1.
