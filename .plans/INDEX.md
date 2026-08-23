# Plans

## Active

## Planned

- [ ] Token-threshold wrap trigger hook: nudge /wrap instead of /compact near context limit (see [2026-08-23-field-survey-adoptions.md](2026-08-23-field-survey-adoptions.md))
- [ ] Worktree list-only awareness in Sync step (same plan file)
- [ ] PreCompact hook: snapshot handover before auto-compaction eats in-progress state (idea from REMvisual claude-handoff)
- [ ] SSH host alias for bitbonsai account (optional; HTTPS works)

## Recently shipped

- [x] v2.9.0 — references/style.md: prose rules for plan files, INDEX, handovers (distilled unslop); pointers from Sync and Handover steps
- [x] v2.8.0 — field-survey adoptions: secret scrub before next.md/AGENTS.md, resume-side skepticism + anti-fabrication, staleness guard (branch/20+ commits), numeric prune threshold (25→20), one-off-fluke filter
- [x] v2.7.0 — pi package: one install = skill + extension (repo gains package.json pi manifest), host-aware wrap flow (/new vs /clear, both installers, detection via queue script), YAML description fix that unbroke skills.sh installs
- [x] v2.6.0 — eval-driven: headless wraps now create AGENTS.md (gotchas survived only one read before), handover gains "What didn't work" + git drift check, description covers soft endings with negative guards; behavior eval 3 scenarios + trigger eval (harness proved unreliable, see memory)
- [x] v2.4.0 — critical-review fixes: scripts allowlisted via ${CLAUDE_SKILL_DIR}, Pi pointer scoped to its project + stale cleanup, queue gated on extension, mv backup, scripts/test.sh, .plans committed here, symlink chain replaces copy-sync
Archived plans: .plans/.archive/
