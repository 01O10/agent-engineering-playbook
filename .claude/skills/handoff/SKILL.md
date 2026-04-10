---
name: handoff
description: Create or accept a handoff of incomplete work
argument-hint: '[accept [id]]'
---

# Handoff

Transfer incomplete work between sessions or agents. Captures what was being worked on,
where things left off, and concrete next steps.

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. If empty          -> analyze session, create handoff
2. If "accept"       -> list pending, accept one
3. If "accept <id>"  -> accept specific handoff
4. If "list"         -> list all handoffs
```

---

## Create Mode (default)

Analyze the current conversation for incomplete work:

1. Check for active pinned task: `slf agent task`
2. Identify what was being worked on from conversation
3. Determine what's left to do
4. List files that were modified
5. Note any blockers

Then create the handoff:

```bash
slf handoff create "summary" \
  --state "where things left off" \
  --step "next action 1" \
  --step "next action 2" \
  --file "path/to/modified.py" \
  --task <task-id-if-any>
```

Output:

```markdown
## Handoff Created

**ID**: abc12345
**Summary**: [what was being worked on]
**State**: [where things left off]

### Next Steps
1. [concrete action]
2. [concrete action]

### Files Touched
- path/to/file.py

The next session will see this handoff in their startup context.
```

## Accept Mode

```bash
slf handoff list          # show pending
slf handoff accept <id>   # accept specific one
```

When accepting, display the full handoff context:
- Summary and state
- All next steps
- Files touched
- Any related task

If a task_id is present, pin it: `slf tasks start <task-id>`

---

## Constraints

- Always include concrete next steps (not vague "continue working")
- Include file paths so the next agent knows where to look
- Reference task IDs when applicable
- Handoffs expire after 10 sessions if not accepted
