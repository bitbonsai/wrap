---
name: wrap
description: End-of-session wrap-up that extracts gotchas from the session, routes them to AGENTS.md and auto-memory, syncs README and plan files, and writes a handover prompt so the next session picks up where this one left off. Use when the user says "wrap", "wrap up", "wrap this session", "save learnings", "end of session", "I'm done for now", "let's wrap", "remember this session", "clear context", or any variation of closing out a work session and preserving what was learned. Also trigger on softer session-ending signals: done for the day, stepping away or heading to a meeting, parking in-progress work for a fresh session, context getting long, or about to run /clear. Not for wrapping text or lines, wrapping content into another format, or clearing caches.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(mkdir:*), Bash(mv:*), Bash(${CLAUDE_SKILL_DIR}/scripts/*)
metadata:
  version: 2.6.0
---

# Wrap

End-of-session wrap-up. Goal: improve future agent performance. Persist what the code can't tell the next agent, then hand over in-progress work.

Flow: **Extract & route → Sync → Handover.** Setup (missing files, hook) happens as a side effect along the way.

## Session context (auto-collected)

- Branch: !`git branch --show-current 2>/dev/null || echo "not a git repo"`
- Working tree: !`git status --porcelain 2>/dev/null | head -20`
- Recent commits: !`git log --oneline -5 2>/dev/null || echo "no commits"`

Use this for the handover. Don't re-run these commands unless the state changed after wrap started. If your harness didn't auto-execute the substitutions above, run the three commands yourself.

## Files wrap maintains

- **`AGENTS.md`** (committed): brief repo description plus gotchas. The primary store: travels with `git clone`, auto-loaded by Claude Code, Pi, OpenCode, and Cursor. If the project uses `CLAUDE.md` for this role, update that instead of creating a second file.
- **Auto-memory**: personal preferences and machine-specific facts only. On Claude Code the path is given in your system prompt (don't guess it). On hosts without persistent memory, put these facts in the handover instead; never commit them.
- **`.plans/INDEX.md`** (committed): lightweight tracker with Active, Planned, and Recently shipped sections.
- **`.plans/*.md`** plan files (committed): named `YYYY-MM-DD-slug.md`. Shipped/abandoned ones live in `.plans/.archive/`.
- **`.plans/next.md`** (gitignored): the handover prompt, consumed by the Claude SessionStart hook or Pi extension.

**Missing files: create silently.** Seed from this session using [references/templates.md](references/templates.md), mention what was created in the closing summary, and let git be the review. Never ask permission to create these. In a git repo, ensure `.gitignore` contains `.plans/next.md` and `.plans/next.prev.md`.

**Legacy files:** if `globalcontext.md` or `agent-learnings.md` exist, fold their non-derivable content into AGENTS.md (`## Gotchas`) and delete them. AGENTS.md is the only store; no overflow or side files. Skip lines derivable from the repo (stack, commands visible in package.json etc.), and update any references to the deleted files (CLAUDE.md/AGENTS.md `@includes`, "see agent-learnings.md" pointers). Mention the fold in the closing summary; git is the review. If the user objects, record that in auto-memory and never fold in that repo again.

**Handover automation (the only setup question):** if `.plans/` exists, either the project's `.claude/settings.json` lacks the wrap SessionStart hook or the global Pi wrap extension is missing, and there's no record of the user declining, ask once whether to install auto-handover support (AskUserQuestion on Claude Code, a plain question on other interactive hosts). Both integrations inject `.plans/next.md` once, then archive it to `.plans/next.prev.md`. On yes, run these from the project root (both idempotent; the Claude installer uses jq or python3; Claude Code substitutes `${CLAUDE_SKILL_DIR}`, other hosts use the directory containing this SKILL.md):

```bash
${CLAUDE_SKILL_DIR}/scripts/install-hook.sh
${CLAUDE_SKILL_DIR}/scripts/install-pi-extension.sh
```

The Claude hook handles startup and `/clear`. The global Pi extension handles startup and `/new`; the queued pointer in `~/.pi/agent/wrap-next.json` lets it find the handover when the session starts in a subdirectory of the wrapped project (a pointer from a different project is ignored and restored). If the Claude installer fails, follow [references/hook.md](references/hook.md). On decline, save the decline to auto-memory so no future wrap re-asks.

**Non-interactive session** (headless, CI): ask nothing, install nothing (no hooks, no extensions). Still maintain the files above, creating them if missing: a gotcha that only lives in the handover dies after one read, so skipping AGENTS.md here loses it.

**Degrade by capability.** Any host that reads Agent Skills (OpenCode, Cursor, others) runs the core flow; when a feature named here is missing, apply the fallback and move on:
- No AskUserQuestion → ask the setup question in plain text; if that's not possible, skip setup entirely.
- No auto-memory → personal and machine facts go in the handover; persist a setup decline as `<!-- wrap: auto-handover declined -->` at the top of `.plans/INDEX.md` so no future wrap re-asks.
- No SessionStart hooks or extensions → skip the installers; close by telling the user to point the next session at `.plans/next.md`.

## Step 1: Extract & route

Review the conversation for GOTCHAS ONLY; everything else is recoverable from git or the code. A gotcha is:

1. **Something that broke**: caused a bug, wasted time, or required a fix
2. **A wrong assumption**: had to be corrected mid-session
3. **Counterintuitive behavior**: an API, tool, or system that doesn't work how you'd expect

NOT gotchas: what shipped (git log has it), feature descriptions, timelines, anything derivable from reading the code.

Route each fact to exactly ONE home:

- True for anyone who clones the repo → **AGENTS.md** (under a `## Gotchas` section)
- Personal preference or workflow correction ("don't do X", "I prefer Y") → **auto-memory**, feedback-type entry, include WHY
- Machine-specific fact (local auth quirks, paths) → **auto-memory**
- In-progress state → the **handover** (Step 3), nowhere else

Never write the same fact to two homes; duplicates drift apart and the next agent can't tell which one is true. Gotchas always live inline in AGENTS.md; never split them into a separate file. If the list outgrows about a page, prune it: drop lines that became derivable from the code, were fixed, or never recurred.

Write every line caveman-style: max compression, zero filler. Drop articles, hedging, framing; keep exact technical terms, paths, commands. One line per fact. `[thing] [breaks/needs] [why]. [fix].` beats a paragraph.

```
Bad:  defers rendering by keeping the old value until the browser has idle capacity
Good: defers render: keeps old value until browser idle
```

## Step 2: Sync

Fix contradictions the session created. Contradiction-triggered only, don't refresh files for the sake of it.

- **README**: if the session changed something README documents (commands, install steps, usage, config), update that section only, preserving the existing voice and structure. Otherwise don't touch it.
- **`.plans/INDEX.md`**: move completed items to "Recently shipped" (keep 5; drop older lines, git history keeps them), add plans created this session, drop Planned items that were superseded.
- **Plan files**: save any plan doc produced this session as `.plans/YYYY-MM-DD-slug.md` and list it in INDEX. Move plan files for shipped or abandoned work from `.plans/` to `.plans/.archive/` (`mkdir` if missing); on first archive, add the footer line `Archived plans: .plans/.archive/` to INDEX.md if missing. Only active and planned plan files stay in `.plans/` root.
- **Auto-memory**: delete entries for gotchas FIXED this session, deletion IS the update, never mark `[FIXED]` or rewrite as "fixed by...". Correct entries the session proved inaccurate.
- **AGENTS.md**: correct any existing line the session proved wrong.

## Step 3: Handover

If nothing is in progress (pure Q&A session), skip the handover: summarize what was saved and stop.

Build a self-contained prompt a fresh agent with zero context can pick up from:

```
Branch: {branch} (PR #{number} if applicable)

What shipped this session: {brief list of changes, with filenames}

Status: {built locally / pushed / deployed}. {test results}. {typecheck status}.

What still needs doing:
1. {next step}

What didn't work (don't retry):
- {approaches tried and abandoned this session, with why}

Known gaps / follow-up:
- {anything deferred or incomplete}

Before acting on this handover, run git status and git log; if reality differs from the state above, trust reality and flag the drift.
```

Drop the "didn't work" section if nothing was tried and abandoned; keep the git check line always.

Include file paths for anything created or significantly changed, the git state (committed? pushed?) from the auto-collected context, and a reference to the plan file if one exists. Factual, no fluff.

Then:

1. **Backup first, always.** If `.plans/next.md` exists, run `mv .plans/next.md .plans/next.prev.md` BEFORE writing anything else (overwriting the old backup is fine). Never Write over an existing `next.md`: it may hold an unconsumed handover, and overwriting destroys the only copy.
2. Write the handover to `.plans/next.md`.
3. Queue that exact file for Pi. Run from the project root:
   ```bash
   ${CLAUDE_SKILL_DIR}/scripts/queue-pi-handover.sh .plans/next.md
   ```
   No-op when the Pi extension isn't installed; otherwise writes the absolute handover path to `~/.pi/agent/wrap-next.json` (latest wrap wins).
4. Close with a brief summary of what was saved, created, or synced ("nothing new" is a valid answer), then tell the user how to continue:
   - Pi extension installed: run `/new`; the new session picks the queued handover up automatically.
   - Claude hook installed: run `/clear`; the next session picks the handover up automatically.
   - Neither installed: start the next session in the project and tell the agent to read `.plans/next.md`.
