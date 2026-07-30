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

If the gotcha list outgrows about a page, move it to `agent-learnings.md` (sections: Code traps, Deploy flow, Infrastructure, Testing) and leave one line in AGENTS.md: `Gotchas: see agent-learnings.md`.

## .plans/INDEX.md

```markdown
# Plans

## Active
- [ ] {in-progress item from this session}

## Planned

## Recently shipped
```

## .gitignore entries

Always append (git repos only):

```
.plans/next.md
.plans/next.prev.md
```
