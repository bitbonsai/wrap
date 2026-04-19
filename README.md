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

### skills.sh

```bash
npx skills add github:bitbonsai/wrap
```

You can use [skills.sh](https://skills.sh) to add this skill globally.

### Claude Code

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

The skill works with any repo, but it's designed to augment a few specific files. It updates all of these if present, skips silently if not.

### `agent-learnings.md`

A running list of gotchas organized by category. Think of it as your project's "lessons learned" log.

```markdown
## Code traps
- Don't use `find -delete` — it deletes directories matching the pattern too
- `bun run` doesn't pass env vars the same way as `npm run`

## Deploy flow
- Always run `terraform plan` before `apply` — the staging state drifts fast

## Infra
- The ECS cluster name is `prod-web`, not `production-web`
```

**Why it helps:** Future agents don't have to relearn the hard way. A single gotcha can save hours of debugging the same trap twice.

### `globalcontext.md`

A living orientation snapshot. One page that answers "what is this thing and how do I work on it?"

```markdown
# MyProject

- **Stack:** Next.js 14, Tailwind, PostgreSQL, Vercel
- **Node version:** 20.x
- **Key env vars:** `DATABASE_URL`, `OPENAI_API_KEY`
- **Dev server:** `bun run dev` (port 3000)
- **Active work:** Migrating auth from JWT to OAuth2
- **Last deploy:** 2026-04-19
```

**Why it helps:** When an agent joins a session cold (especially after `/clear`), it has zero context. This file is a cheat sheet that prevents the "what framework is this again?" warm-up loop.

### `.plans/INDEX.md`

A lightweight project tracker with three sections:

```markdown
## Active
- [ ] Add dark mode toggle (waiting on design tokens)
- [ ] Refactor webhook handlers to use Bull queues
- [ ] Fix flaky e2e test on `/dashboard/billing`

## Planned
- [ ] Migrate from Stripe Checkout to Payment Elements
- [ ] Add real-time collaboration via Y.js
- [ ] Evaluate Vercel Edge vs Node runtime for API routes

## Recently shipped
- [x] v2.4.0 — Team billing + seat management
- [x] Migrated auth from JWT to OAuth2 (GitHub + Google)
- [x] Switched test runner from Jest to Vitest
```

**Why it helps:** Agents constantly lose track of what's in progress versus what's done. A simple index prevents "did we already do this?" and keeps work organized without a full project management tool.
