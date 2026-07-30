---
name: wrap
description: End-of-session wrap-up that extracts gotchas from the session, routes them to AGENTS.md and auto-memory, syncs README and plan files, and writes a handover prompt so the next session picks up where this one left off. Use when the user says "wrap", "wrap up", "wrap this session", "save learnings", "end of session", "I'm done for now", "let's wrap", "remember this session", "clear context", or any variation of closing out a work session and preserving what was learned. Also trigger when the user says they're about to run /clear.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(mkdir:*), Bash(mv:*)
metadata:
  version: 2.0.1
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

- **`AGENTS.md`** (committed) — brief repo description plus gotchas. The primary store: travels with `git clone`, auto-loaded by Claude Code and OpenCode. If the project uses `CLAUDE.md` for this role, update that instead of creating a second file.
- **Auto-memory** (path given in your system prompt; don't guess it) — personal preferences and machine-specific facts only.
- **`.plans/INDEX.md`** (committed) — lightweight tracker: Active / Planned / Recently shipped.
- **`.plans/next.md`** (gitignored) — the handover prompt, consumed by the SessionStart hook.

**Missing files: create silently.** Seed from this session using [references/templates.md](references/templates.md), mention what was created in the closing summary, and let git be the review. Never ask permission to create these. In a git repo, ensure `.gitignore` contains `.plans/next.md` and `.plans/next.prev.md`.

**Legacy files:** if `globalcontext.md` or `agent-learnings.md` exist, offer once (AskUserQuestion) to fold their non-derivable content into AGENTS.md and delete them. Skip lines derivable from the repo (stack, commands visible in package.json etc.). If the user declines, record that in auto-memory and never offer again. Exception: an `agent-learnings.md` that AGENTS.md already references is the intentional overflow file, keep it and append there.

**Hook (the only setup question):** if `.plans/` exists, the project's `.claude/settings.json` has no wrap SessionStart hook, and auto-memory has no record of the user declining, ask once with AskUserQuestion whether to install the auto-handover hook. It injects `.plans/next.md` into the next session, then moves it to `.plans/next.prev.md` so a stale handover is never read twice. On yes, run exactly this from the project root (idempotent, uses jq or python3; if it fails, follow [references/hook.md](references/hook.md)):

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/install-hook.sh"
```

On decline, save the decline to auto-memory so no future wrap re-asks.

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

Never write the same fact to two homes. If AGENTS.md's gotcha list outgrows about a page, split it into `agent-learnings.md` and leave a one-line reference in AGENTS.md.

Write every line caveman-style: max compression, zero filler. Drop articles, hedging, framing; keep exact technical terms, paths, commands. One line per fact. `[thing] [breaks/needs] [why]. [fix].` beats a paragraph.

```
Bad:  defers rendering by keeping the old value until the browser has idle capacity
Good: defers render: keeps old value until browser idle
```

## Step 2: Sync

Fix contradictions the session created. Contradiction-triggered only, don't refresh files for the sake of it.

- **README**: if the session changed something README documents (commands, install steps, usage, config), update that section only, preserving the existing voice and structure. Otherwise don't touch it.
- **`.plans/INDEX.md`**: move completed items to "Recently shipped" (keep ~5), add plans created this session.
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
3. Close with a brief summary of what was saved, created, or synced ("nothing new" is a valid answer), then tell the user how to continue, depending on whether the wrap hook is in `.claude/settings.json`:
   - Hook installed: run `/clear`; the next session picks the handover up automatically.
   - No hook: after `/clear`, tell the new agent to read `.plans/next.md`.
