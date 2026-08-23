# Prose rules for wrap artifacts

Applies to plan files, INDEX entries, handover prose, and closing summaries. Gotcha lines have their own stricter rule in SKILL.md (caveman compression); these rules cover everything longer than a line. Never rewrite code, commands, exact quotes, error messages, identifiers, or paths.

## The one test

Every sentence must tell the next reader what to do or know. If it can't become a concrete instruction, fact, or number, cut it. If the sentence could appear unchanged in another project's plan, it says nothing about this one.

## Write

- Mechanism and numbers, not feelings: "cache cut build 40s → 9s", not "significantly improved performance".
- Name actors and reasons: "user rejected X because Y", not "it was decided". A decision without its why is dead weight next session.
- Active voice when the actor matters: "the installer removes the copy", not "the copy is removed".
- Plain words: use, help, many, if. Not leverage, facilitate, numerous, utilize, in the event that.
- One idea per sentence. If the reader must backtrack, split it.

## Cut

- Puffery and generic conclusions: robust, comprehensive, seamless, "sets the stage", "the future looks bright".
- Hedging stacks: "could potentially possibly" becomes "may", or state the fact.
- "Not just X, but Y". State the point directly.
- Forced groups of three. Use the natural number of items.
- Bold labels that restate the line: "**Testing:** tests were added".
- Decorative emoji, Title Case Headings, filler ("in order to" becomes "to"; delete "it is important to note").
- AI vocabulary: delve, crucial, pivotal, showcase, underscore, testament, landscape or tapestry as abstractions.
- Em dashes as habitual connectors. Prefer a period or comma.

## Litmus before saving a plan file

Read it as the next session's agent with zero context. Is every Planned item actionable? Does every decision carry its why? Is anything here something you'd still have to re-derive? Fix those lines, delete the rest.
