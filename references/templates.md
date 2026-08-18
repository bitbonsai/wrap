# Seed templates

Templates for files created silently when missing. Fill placeholders from session context; drop any section you have nothing for. Keep seeds minimal, these files grow through use, not at creation.

## AGENTS.md

```markdown
# {project name}

{one line: what this repo is and does}

{only non-derivable facts: unusual conventions, commands that aren't in package.json/Makefile, deploy quirks. Nothing an agent can learn by reading the repo.}

## Gotchas

- {gotchas extracted this session, one line each}
```

If the gotcha list outgrows about a page, prune it (drop fixed/derivable/stale lines) — never move gotchas to a separate file. Group with subheadings inside `## Gotchas` (Code traps, Deploy flow, Infrastructure, Testing) if grouping helps.

## .plans/INDEX.md

```markdown
# Plans

## Active
- [ ] {in-progress item from this session}

## Planned

## Recently shipped

Archived plans: .plans/.archive/
```

Plan files are named `YYYY-MM-DD-slug.md`. When a plan ships or is abandoned, move its file to `.plans/.archive/` — the date-prefixed names keep the archive browsable without an index.

## .gitignore entries

Always append (git repos only):

```
.plans/next.md
.plans/next.prev.md
```
