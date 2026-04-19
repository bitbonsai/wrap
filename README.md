<div align="center">
	<br>
	<img width="137" height="137" src="icon.svg" alt="Wrap">
	<br>
	<br>
	<h1>wrap</h1>
	<p>End-of-session wrap-up for <a href="https://github.com/anthropics/claude-code">Claude Code</a>. Extract gotchas, save learnings, reset with confidence.</p>
	<br>
	<br>
</div>

> Most session logs are noise. "Shipped v3.57.4" is in git. "CSS is 18KB now" is in the code. The only thing worth persisting is what went **wrong** and what the user **prefers** — because those are invisible to future agents reading the codebase.

## Install

```bash
claude skill install /path/to/wrap
# or
claude skill install github:bitbonsai/wrap
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

1. **Extracts gotchas** — things that broke, wrong assumptions, counterintuitive behavior
2. **Saves to project memory** — updates `MEMORY.md` with gotchas, user preferences, and cleans stale entries
3. **Updates project files** — if `agent-learnings.md`, `globalcontext.md`, or plan files exist, keeps them current
4. **Prompts for context reset** — so you can `/clear` with confidence

## What it does NOT record

- What was shipped (git log has this)
- Feature descriptions (docs have this)
- Rollout timelines
- Anything derivable from reading the code

## Recommended project setup

For best results, keep these files in your repo:

- **`agent-learnings.md`** — gotcha list organized by category (code traps, deploy flow, infra, testing)
- **`globalcontext.md`** — living orientation snapshot (version, architecture, env vars, active work)
- **`.plans/INDEX.md`** — plan tracker with Active/Planned/Recently shipped sections

The skill updates all of these if present, skips silently if not.
