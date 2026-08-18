---
name: wrap
description: End-of-session wrap-up that extracts gotchas from the session, routes them to AGENTS.md and auto-memory, syncs README and plan files, and writes a handover prompt so the next session picks up where this one left off. Use when the user says "wrap", "wrap up", "wrap this session", "save learnings", "end of session", "I'm done for now", "let's wrap", "remember this session", "clear context", or any variation of closing out a work session and preserving what was learned. Also trigger when the user says they're about to run /clear.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(mkdir:*), Bash(mv:*)
metadata:
  version: 2.3.0
---

# Wrap

End-of-session wrap-up. Goal: improve future agent performance. Persist what the code can't tell the next agent, then hand over in-progress work.

Flow: **Extract & route → Sync → Handover.** Setup (missing files, hook) happens as a side effect, not a phase.

## Session context (auto-collected)

- Branch: !`git branch --show-current 2>/dev/null || echo "not a git repo"`
- Working tree: !`git status --porcelain 2>/dev/null | head -20`
- Recent commits: !`git log --oneline -5 2>/dev/null`

Use this for the handover. Don't re-run these commands unless the state changed after wrap started.

## Files wrap maintains

- **`AGENTS.md`** (committed) — brief repo description plus gotchas. The primary store: travels with `git clone`, auto-loaded by Claude Code, Pi, and OpenCode. If the project uses `CLAUDE.md` for this role, update that instead of creating a second file.
- **Auto-memory** (path given in your system prompt; don't guess it) — personal preferences and machine-specific facts only.
- **`.plans/INDEX.md`** (committed) — lightweight tracker: Active / Planned / Recently shipped.
- **`.plans/*.md`** plan files (committed) — named `YYYY-MM-DD-slug.md`. Shipped/abandoned ones live in `.plans/.archive/`.
- **`.plans/next.md`** (gitignored) — the handover prompt, consumed by the Claude SessionStart hook or Pi extension.

**Missing files: create silently.** Seed from this session using [references/templates.md](references/templates.md), mention what was created in the closing summary, and let git be the review. Never ask permission to create these. In a git repo, ensure `.gitignore` contains `.plans/next.md` and `.plans/next.prev.md`.

**Legacy files:** if `globalcontext.md` or `agent-learnings.md` exist, fold their non-derivable content into AGENTS.md (`## Gotchas`) and delete them — AGENTS.md is the only store; no overflow or side files. Skip lines derivable from the repo (stack, commands visible in package.json etc.), and update any references to the deleted files (CLAUDE.md/AGENTS.md `@includes`, "see agent-learnings.md" pointers). Mention the fold in the closing summary; git is the review. If the user objects, record that in auto-memory and never fold in that repo again.

**Handover automation (the only setup question):** if `.plans/` exists, either the project's `.claude/settings.json` lacks the wrap SessionStart hook or the global Pi wrap extension is missing, and auto-memory has no record of the user declining, ask once with AskUserQuestion whether to install auto-handover support. Both integrations inject `.plans/next.md` once, then archive it to `.plans/next.prev.md`. On yes, run these from the project root (both idempotent; the Claude installer uses jq or python3):

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/install-hook.sh"
bash "${CLAUDE_SKILL_DIR}/scripts/install-pi-extension.sh"
```

The Claude hook handles startup and `/clear`. The global Pi extension handles startup and `/new`, including sessions whose cwd differs from the wrapped worktree via `~/.pi/agent/wrap-next.json`. If the Claude installer fails, follow [references/hook.md](references/hook.md). On decline, save the decline to auto-memory so no future wrap re-asks.

**Non-interactive session** (headless, CI): ask nothing, create nothing new; still update existing files and write the handover.

## Step 1: Extract & route

Review the conversation for GOTCHAS ONLY. A gotcha is:

1. **Something that broke** — caused a bug, wasted time, or required a fix
2. **A wrong assumption** — had to be corrected mid-session
3. **Counterintuitive behavior** — an API, tool, or system that doesn't work how you'd expect

NOT gotchas: what shipped (git log has it), feature descriptions, timelines, anything derivable from reading the code.

Route each fact to exactly ONE home:

- True for anyone who clones the repo → **AGENTS.md** (under a `## Gotchas` section)
- Personal preference or workflow correction ("don't do X", "I prefer Y") → **auto-memory**, feedback-type entry, include WHY
- Machine-specific fact (local auth quirks, paths) → **auto-memory**
- In-progress state → the **handover** (Step 3), nowhere else

Never write the same fact to two homes. Gotchas always live inline in AGENTS.md — never split them into a separate file. If the list outgrows about a page, prune it: drop lines that became derivable from the code, were fixed, or never recurred.

Write every line caveman-style: max compression, zero filler. Drop articles, hedging, framing; keep exact technical terms, paths, commands. One line per fact. `[thing] [breaks/needs] [why]. [fix].` beats a paragraph.

```
Bad:  defers rendering by keeping the old value until the browser has idle capacity
Good: defers render: keeps old value until browser idle
```

## Step 2: Sync

Fix contradictions the session created. Contradiction-triggered only, don't refresh files for the sake of it.

- **README**: if the session changed something README documents (commands, install steps, usage, config), update that section only, preserving the existing voice and structure. Otherwise don't touch it.
- **`.plans/INDEX.md`**: move completed items to "Recently shipped" (keep 5; drop older lines, git history keeps them), add plans created this session, drop Planned items that were superseded.
- **Plan files**: move plan files for shipped or abandoned work from `.plans/` to `.plans/.archive/` (`mkdir` if missing). Only active and planned plan files stay in `.plans/` root.
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

Known gaps / follow-up:
- {anything deferred or incomplete}
```

Include file paths for anything created or significantly changed, the git state (committed? pushed?) from the auto-collected context, and a reference to the plan file if one exists. Factual, no fluff.

Then:

1. **Backup first, always.** If `.plans/next.md` exists, copy its contents into `.plans/next.prev.md` using Read + Write (no `mv`, no Bash, avoids a permission prompt): Read `.plans/next.md`; if `.plans/next.prev.md` exists, Read it too (Write refuses to overwrite an unread file); then Write the old handover to `.plans/next.prev.md`. Do this BEFORE writing anything else. Never Write over an existing `next.md`.
2. Write the handover to `.plans/next.md`.
3. Queue that exact file for Pi. Run from the project root:
   ```bash
   bash "${CLAUDE_SKILL_DIR}/scripts/queue-pi-handover.sh" .plans/next.md
   ```
   This writes only the absolute handover path to `~/.pi/agent/wrap-next.json`; the latest wrap wins.
4. Close with a brief summary of what was saved, created, or synced ("nothing new" is a valid answer), then tell the user how to continue:
   - Pi extension installed: run `/new`; the new session picks the queued handover up automatically.
   - Claude hook installed: run `/clear`; the next session picks the handover up automatically.
   - Neither installed: start the next session in the project and tell the agent to read `.plans/next.md`.
