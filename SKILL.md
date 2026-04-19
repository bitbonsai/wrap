---
name: wrap
description: End-of-session wrap-up that saves learnings to memory and prepares for context reset. Use when the user says "wrap", "wrap up", "wrap this session", "save learnings", "end of session", "I'm done for now", "let's wrap", "remember this session", "clear context", or any variation of closing out a work session and preserving what was learned. Also trigger when the user says they're about to run /clear.
---

# Wrap

End-of-session wrap-up. Primary goal: improve future agent performance.

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

Update auto-memory MEMORY.md (`~/.claude/projects/<current-project>/memory/`):

**Add new entries:**
- Gotchas and corrections discovered this session
- User preferences or workflow corrections ("don't do X", "I prefer Y", "stop doing Z"). These go in `feedback` type memory files. Include WHY the user wants it that way
- Non-obvious project context learned this session

**Clean stale entries:**
- Scan MEMORY.md for bugs/gotchas that were FIXED this session. Remove or mark resolved
- Update entries that are now inaccurate based on work done this session
- Check if any "Active Projects" items were completed

Keep entries concise (1-2 lines each). Do NOT duplicate what's already there.

This is the most important step. Memory persists across all future sessions.

## Step 3: Update project files (if they exist)

Check for these files and update if present. Skip silently if missing.

**agent-learnings.md**: Append new gotchas under the right section (Code traps, Deploy flow, Infrastructure, Testing). Skip duplicates.

**globalcontext.md**: Update version + recent releases table if version was bumped. Update "Active work" if work was completed. Update "Known issues" if new issues found or old ones resolved.

**.plans/next-steps.md**: Update "Current state" header if version was bumped. Update "Known issues" if issues resolved or new ones found.

**.plans/INDEX.md**: Move completed plans to "Recently shipped". Add new plans if created during session. Keep "Recently shipped" to last ~5 entries.

## Step 4: Confirm and prompt reset

Show brief summary of what was saved (or "nothing new" if nothing qualified). Then: "Learnings saved. You can now run /clear to reset context."
