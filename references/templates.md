# Seed templates

Templates for files created in Step 3. Fill placeholders from session context; drop any section you have nothing for. Keep seeds minimal, these files grow through use, not at creation.

## globalcontext.md

```markdown
# {project name}

- **Stack:** {frameworks, language, database, hosting}
- **Runtime:** {node/python/etc version}
- **Key env vars:** {names only, never values}
- **Dev server:** {command} (port {port})
- **Test:** {command}
- **Active work:** {what's in progress right now}
- **Last deploy:** {date, if known}
```

## agent-learnings.md

```markdown
# Agent learnings

Gotchas only. One line each. Newest at top of its section.

## Code traps

## Deploy flow

## Infrastructure

## Testing
```

Seed with any gotchas already extracted in Step 1.

## .plans/INDEX.md

```markdown
# Plans

## Active
- [ ] {in-progress item from this session}

## Planned

## Recently shipped
```

## .gitignore entries

Always append (Step 3, git repos only):

```
.plans/next.md
.plans/next.prev.md
```
