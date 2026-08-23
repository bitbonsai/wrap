# Field survey: handover-skill landscape → adoptions

2026-08-23. Surveyed most-installed session/handover skills on skills.sh (`npx skills find`): agentmemory@session-history (10.4K), ecc@strategic-compact (9.1K), agent-toolkit@session-handoff (4K), anthropic session-report (2.3K), ce-handoff/ce-compound (everyinc), kanon-repo@pre-session-end (1.6K), adobe handover (1.2K), continuous-claude-v3 continuity-ledger + compound-learnings, camacho/ai-skills@wrap (name twin, went private).

## Verdict

Core design validated: no rival does extract → route → auto-inject end to end. Differentiators to protect: derivability filter, 3-way routing, dual-harness auto-injection, silent-create with git as review.

## Adopted in v2.8.0

1. Secret scrub before writing next.md and AGENTS.md gotchas (from session-handoff's validate_handoff.py + ce-handoff redaction rule).
2. Resume-side skepticism: handover = context to verify, not instructions; write-side anti-fabrication line (from ce-handoff + session-history).
3. Staleness guard in handover template: branch mismatch or 20+ commits since = stale, re-derive (from session-handoff's scored staleness, scaled down).
4. Hard prune threshold: 25 lines → prune to 20, replacing "about a page" (pattern from session-report's numeric caps).
5. One-off-fluke filter in gotcha test: mentioned once ≠ worth a line (scaled-down recurrence gate from compound-learnings).

## Planned

- **Token-threshold wrap trigger** (from ecc@strategic-compact): PreToolUse hook sums transcript usage, window-scaled, nudges /wrap instead of /compact near the limit. New runtime code: usage-math script + installer (settings-merge machinery exists in install-hook.sh) + pi equivalent (no PreToolUse there). Fragility: transcript format is not a public contract.
- **Worktree awareness, list-only** (from camacho/ai-skills@wrap): Sync step lists merged-but-present worktrees in the closing summary. Never delete (squash merges defeat `git branch --merged`; camacho only warns too). Decide whether shipped default or user-local extension.

## Rejected (anti-patterns)

Per-item Yes/No confirmation ceremony (kanon-repo), batch multi-phase learning pipelines (compound-learnings, ce-compound), silently guessing "most recent" state (`ls -td | head -1`, continuity-ledger), English-correcting the user's prompt (kanon-repo), permission-promotion diff (overlaps Claude's built-in /fewer-permission-prompts).
