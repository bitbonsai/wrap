---
name: wrap
description: End-of-session wrap-up that saves learnings to memory and prepares for context reset. Use when the user says "wrap", "wrap up", "wrap this session", "save learnings", "end of session", "I'm done for now", "let's wrap", "remember this session", "clear context", or any variation of closing out a work session and preserving what was learned. Also trigger when the user says they're about to run /clear.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(mkdir:*)
---

# Wrap

End-of-session wrap-up. Primary goal: improve future agent performance.

## Session context (auto-collected)

- Branch: !`git branch --show-current 2>/dev/null || echo "not a git repo"`
- Working tree: !`git status --porcelain 2>/dev/null | head -20`
- Recent commits: !`git log --oneline -5 2>/dev/null`

Use this for the handover prompt in Step 6. Don't re-run these commands unless the state changed after wrap started.

## Checklist

Copy this checklist and check off each step as you complete it:

- [ ] 1. Extract gotchas
- [ ] 2. Save to project memory
- [ ] 3. Offer missing project files
- [ ] 4. Offer auto-handover hook
- [ ] 5. Update existing project files
- [ ] 6. Generate handover prompt
- [ ] 7. Save handover, prompt reset

## Step 1: Extract gotchas

Review this conversation for GOTCHAS ONLY. A gotcha is:

1. **Something that broke** -- caused a bug, wasted time, or required a fix
2. **A wrong assumption** -- had to be corrected mid-session
3. **Counterintuitive behavior** -- an API, tool, or system that doesn't work how you'd expect

Do NOT record:
- What was shipped or deployed (git log has this)
- Feature descriptions (agents.md has this)
- Rollout timelines or monitoring results
- UI polish details
- Anything derivable from reading the code

Format: one line per gotcha. Code example only if the fix is non-obvious.

## Step 2: Save to project memory (PRIMARY)

Update auto-memory MEMORY.md. Use the memory directory path given in your system prompt (don't guess it; the on-disk project directory names are munged paths):

**Add new entries:**
- Gotchas and corrections discovered this session
- User preferences or workflow corrections ("don't do X", "I prefer Y", "stop doing Z"). These go in `feedback` type memory files. Include WHY the user wants it that way
- Non-obvious project context learned this session

**Clean stale entries:**
- Scan MEMORY.md for bugs/gotchas that were FIXED this session. Remove or mark resolved
- Update entries that are now inaccurate based on work done this session
- Check if any "Active Projects" items were completed

Write entries caveman-style: max compression, zero filler. Drop articles, hedging, and framing; keep exact technical terms, paths, and commands. One line per fact. `[thing] [breaks/needs] [why]. [fix].` beats a paragraph. Do NOT duplicate what's already there.

This is the most important step. Memory persists across all future sessions.

## Step 3: Offer to create project files (if missing)

If the session is non-interactive (headless, CI, no user available to answer), skip this step and Step 4 entirely: ask nothing, create nothing.

Check for `globalcontext.md`, `agent-learnings.md`, and `.plans/` in the project root.

If any are missing, use the AskUserQuestion tool (multiSelect) to ask which the user wants created:

- **`.plans/`**: holds `INDEX.md` (project tracker) and `next.md` (handover prompt). Needed for Step 7.
- **`globalcontext.md`**: one-page orientation snapshot (stack, commands, active work)
- **`agent-learnings.md`**: running gotchas log by category

Create only what the user selects, seeded with minimal content from this session using the templates in [references/templates.md](references/templates.md). If the user selects nothing, skip and proceed.

**Always gitignore the handover files.** If the project is a git repo and `.plans/` exists (or was just created), ensure `.gitignore` contains `.plans/next.md` and `.plans/next.prev.md`. These are transient per-machine state. Never commit them, and don't ask about them.

If anything was created and the project is a git repo, ask a follow-up with AskUserQuestion: **commit** these files or **add to .gitignore**? The commit covers `globalcontext.md`, `agent-learnings.md`, and `.plans/INDEX.md` only, never `next.md`. Apply the choice (a third option, "leave untracked", does nothing). When committing, use a plain message like `Add agent context files`.

Only ask once per wrap. Do not re-ask about files the user declined earlier in the session.

## Step 4: Offer auto-handover hook (once per project)

If `.plans/` exists and the project's `.claude/settings.json` has no wrap SessionStart hook yet, ask with AskUserQuestion whether to install one. Don't re-ask if the user declined earlier in the session.

The hook injects `.plans/next.md` into context when a new session starts, then moves it to `.plans/next.prev.md` so a stale handover is never read twice.

If the user says yes, run exactly this command from the project root. Do not modify it or hand-edit the JSON yourself:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/install-hook.sh"
```

The script uses `jq` if available, falls back to `python3`, and is idempotent: it appends the hook without touching existing settings, and no-ops if already installed. If it fails (neither tool present, invalid settings JSON), follow the manual merge instructions in [references/hook.md](references/hook.md).

With the hook installed, `/clear` alone is enough: the next session starts with the handover already in context.

## Step 5: Update project files (if they exist)

Check for these files and update if present. Skip silently if missing.

**agent-learnings.md**: Append new gotchas under the right section (Code traps, Deploy flow, Infrastructure, Testing). Skip duplicates.

**globalcontext.md**: Update version + recent releases table if version was bumped. Update "Active work" if work was completed. Update "Known issues" if new issues found or old ones resolved.

**.plans/INDEX.md**: Move completed plans to "Recently shipped". Add new plans if created during session. Keep "Recently shipped" to last ~5 entries.

## Step 6: Generate handover prompt

Build the handover prompt: a self-contained prompt a fresh agent can use to pick up where this session left off (the next agent has zero context).

Structure:

```
Branch: {branch} (PR #{number} if applicable)

What shipped this session: {brief list of changes, with filenames}

Status: {built locally / pushed / deployed}. {test results if run}. {typecheck status}.

What still needs doing:
1. {next step}
2. {next step}
...

Known gaps / follow-up:
- {anything deferred or incomplete}
```

Rules:
- Include file paths for anything created or significantly changed
- State the git status (committed? uncommitted? pushed?) using the auto-collected session context above
- If there's a plan file, reference it
- Keep it factual, no fluff. The prompt must stand alone
- If nothing is in progress (pure Q&A session), skip this step

## Step 7: Save handover and prompt reset

1. Show brief summary of what was saved (or "nothing new" if nothing qualified)
2. If `.plans/next.md` already exists, move it to `.plans/next.prev.md` (keep exactly one backup), then write the new handover prompt to `.plans/next.md`
3. Tell user, depending on whether the SessionStart hook is installed:
   - Hook installed: "Handover saved to .plans/next.md. Run /clear; the next session picks it up automatically."
   - No hook: "Handover saved to .plans/next.md. After /clear, tell the new agent to read .plans/next.md."
4. If `.plans/` doesn't exist and the user declined creating it in Step 3, display the handover prompt in a fenced code block instead and tell the user to copy it manually
