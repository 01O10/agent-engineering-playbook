---
name: insight
description: Review and act on accumulated insights
argument-hint: '[list|act <id>|dismiss <id>|build]'
---

# Insight Review

Review insights generated from accumulated friction patterns and knowledge gaps.

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. If empty or "list" -> show pending insights
2. If "build"         -> run synthesis, show new insights
3. If "act <id>"      -> execute insight action
4. If "dismiss <id>"  -> dismiss insight
```

---

## Default / List Mode

Run: `slf insight list --status pending`

Display pending insights grouped by confidence:
- **HIGH**: Safe to auto-apply
- **MEDIUM**: Review before applying
- **LOW**: Informational only

Ask user which to act on or dismiss.

## Build Mode

Run: `slf insight build`

This synthesizes new insights from accumulated observations.
Show the results and ask which to act on.

## Act Mode

Run: `slf insight act <id>`

The action depends on insight type:
- `add-glossary-term` -> appends to `.self/domain/glossary.md`
- `add-rule` -> appends to `.self/domain/rules.md`
- `fix-workflow` -> creates task in backlog
- `create-skill` -> creates task for manual skill creation

## Dismiss Mode

Run: `slf insight dismiss <id>`

Marks the insight as dismissed. It won't appear in future lists.

---

## Constraints

- Never auto-apply without showing the user first
- HIGH confidence insights can be batch-applied with user approval
- Always show evidence chain before acting
