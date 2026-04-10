---
name: note
description: Stage an observation for next session save
argument-hint: '"observation" | .'
---

# Stage Note

Stage a note for inclusion in next `/save`.

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. If "." → auto-detect friction from conversation
2. Else → note text to stage
```

**Parse examples:**
```
"friction: grep 5x"     → stage that note
"idea: automate X"      → stage that note
"."                     → auto-detect friction
```

---

## Subcommand: Note Text

When given explicit text:

1. Read existing `.prm/staged-notes.md` (create if missing)
2. Append timestamped note:
   ```markdown
   - [YYYY-MM-DD HH:MM] <observation text>
   ```
3. Confirm staging

### Output

```markdown
**Note staged**: "friction: grep 5x for same pattern"
**Total staged**: 3 notes pending

Run `/sync` to see all staged notes.
Run `/save` to commit them with session.
```

---

## Subcommand: Auto-detect (".")

When given ".":

1. Analyze current conversation for friction patterns
2. Stage each detected pattern
3. Show what was staged

### Friction Detection

| Pattern | Example |
|---------|---------|
| Same tool 3+ times similar targets | Multiple Grep refining pattern |
| Backtracking phrases | "wait", "actually", "let me try" |
| Error → retry → success | Tool failed, adjusted, worked |
| Multi-step for simple goal | 5 reads to find one function |
| Clarification loops | User corrected 2+ times |

### Output

```markdown
**Auto-detected friction**:
- [01-28 14:30] search_thrashing: grep 4x for auth handler
- [01-28 14:35] backtracking: tried hooks, reverted to polling

**Total staged**: 5 notes pending
```

---

## Staged Notes Format

`.prm/staged-notes.md`:
```markdown
## Staged Notes

- [2026-01-28 10:30] friction: grep 5x for same pattern
- [2026-01-28 11:15] decision: use factory pattern
- [2026-01-28 14:22] idea: automate test data
```

---

## Quiet Output

```
+1 staged (4 total)
```

For auto-detect:
```
+2 friction staged (5 total)
```

---

## Constraints

- Notes are staging area only
- Cleared on `/save`
- Prefix with type (friction:, idea:, decision:) for categorization
