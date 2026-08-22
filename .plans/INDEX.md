# Plans

## Active

## Planned

- [ ] PreCompact hook: snapshot handover before auto-compaction eats in-progress state (idea from REMvisual claude-handoff)
- [ ] SSH host alias for bitbonsai account (optional; HTTPS works)

## Recently shipped

- [x] v2.6.0 — eval-driven: headless wraps now create AGENTS.md (gotchas survived only one read before), handover gains "What didn't work" + git drift check, description covers soft endings with negative guards; behavior eval 3 scenarios + trigger eval (harness proved unreliable, see memory)
- [x] v2.4.0 — critical-review fixes: scripts allowlisted via ${CLAUDE_SKILL_DIR}, Pi pointer scoped to its project + stale cleanup, queue gated on extension, mv backup, scripts/test.sh, .plans committed here, symlink chain replaces copy-sync
- [x] v2.1.0 — .plans/.archive for shipped plans, YYYY-MM-DD-slug naming, Recently shipped keeps 5
- [x] Redesign per Claude 5 context-engineering guidance: 3-step flow (Extract & route → Sync → Handover), AGENTS.md replaces globalcontext.md + agent-learnings.md, silent file creation, hook = only question (decline remembered), README contradiction check, legacy migration offer
- [x] Align skill with Anthropic authoring guidelines (dynamic git context, checklist, allowed-tools, references/, install script)

Archived plans: .plans/.archive/
