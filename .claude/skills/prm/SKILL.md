---
name: prm
description: Manage project state - objectives, constraints, status, decisions
argument-hint: '[goal | constraint | status | decision] [action] [args]'
---

# Project Resource Management

Consolidated management of `.self/prm/` files.

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. No args → show PRM overview
2. "goal" → objective management
3. "constraint" → constraint management
4. "status" → status view/update
5. "decision" → log decision
```

**Parse examples:**
```
""                          → show all PRM files overview
"goal"                      → list objectives
"goal add implement auth"   → add objective
"goal done 1"               → mark objective #1 complete
"constraint"                → list constraints
"constraint add must be fast" → add constraint
"status"                    → show current status
"status focus validation"   → update focus
"status blocker CI failing" → add blocker
"status blocker clear"      → clear all blockers
"decision Use JWT stateless" → log decision with rationale
```

---

## Subcommand: Overview (default)

Show all PRM files:

```markdown
## PRM Files (.self/prm/)

  ✓ objectives.md (45 lines)
  ✓ status.md (23 lines)
  ✓ constraints.md (18 lines)
  ✓ decisions.md (89 lines)

Commands: slf prm goal | constraint | status | decision
```

---

## Subcommand: `goal`

Manage project objectives in `objectives.md`.

### `goal` (list)
```markdown
## Objectives

### Active
  1. [ ] Implement auth flow
  2. [ ] Add caching layer

### Completed
  3. [x] Set up CI pipeline

**Progress**: 1/3 complete
```

### `goal add "text"`
```markdown
Added objective #4: Implement auth flow
```

### `goal done N`
```markdown
Objective #2 completed: Add caching layer
```

---

## Subcommand: `constraint`

Manage project constraints in `constraints.md`.

### `constraint` (list)
```markdown
## Constraints

  1. Must use PostgreSQL for persistence
  2. API response time < 200ms
  3. No external dependencies for core logic
```

### `constraint add "text"`
```markdown
Added constraint: Must be fast
```

---

## Subcommand: `status`

View/update project status in `status.md`.

### `status` (show)
```markdown
## Current Status

**Focus**: Cross-dataset validation
**Phase**: Implementation -> Testing
**Blockers**: None

**Last Updated**: 2026-01-31
```

### `status focus "text"`
```markdown
Updated focus: External validation runs
```

### `status phase "text"`
```markdown
Updated phase: Testing -> Production
```

### `status blocker "text"`
```markdown
Added blocker: CI failing on main
```

### `status blocker clear`
```markdown
Cleared all blockers
```

---

## Subcommand: `decision`

Log architectural decisions in `decisions.md`.

### `decision "what" "why"`
```markdown
Decision logged: Use JWT for authentication

## 2026-01-31: Use JWT for authentication

**Status**: Accepted
**Rationale**: Stateless, scales horizontally
**Consequences**: [To be determined]
```

---

## File Locations

| File | Content |
|------|---------|
| `.self/prm/objectives.md` | Project goals (active, completed, dropped) |
| `.self/prm/constraints.md` | Technical and business constraints |
| `.self/prm/status.md` | Current focus, phase, blockers |
| `.self/prm/decisions.md` | Architecture Decision Records |

---

## CLI Equivalent

```bash
slf prm                       # overview
slf prm goal list             # list objectives
slf prm goal add "X"          # add objective
slf prm goal done 1           # mark complete
slf prm constraint list       # list constraints
slf prm constraint add "X"    # add constraint
slf prm status                # show status
slf prm status focus "X"      # update focus
slf prm status blocker "X"    # add blocker
slf prm decision log "X" "Y"  # log decision
```

---

## Migration from /goal

The `/goal` skill is deprecated. Use `/prm`:

| Old | New |
|-----|-----|
| `/goal` | `/prm goal` |
| `/goal add X` | `/prm goal add X` |
| `/goal done X` | `/prm goal done N` |
| `/goal status` | `/prm status` |

The `/decide` skill remains as a convenience alias.

---

## Observation Emission

After any **write** subcommand completes (goal add/done, constraint add, status focus/phase/blocker, decision), emit an observation:

```bash
CHANNEL=$(slf channel current -q)
slf memory observe "progress: prm $SUBCOMMAND completed -- $SUMMARY" \
  -t auto-detected -t progress -t "skill:prm" \
  -c "$CHANNEL"
echo "{\"skill\":\"prm\",\"args\":\"$SUBCOMMAND\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"error\":false}" \
  >> .self/cache/session_traces.jsonl
```

On error:
```bash
slf memory observe "error: prm $SUBCOMMAND failed -- $REASON" \
  -t auto-detected -t error -t "skill:prm" \
  -c "$CHANNEL"
echo "{\"skill\":\"prm\",\"args\":\"$SUBCOMMAND\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"error\":true}" \
  >> .self/cache/session_traces.jsonl
```

**Skip observation for read-only subcommands** (overview, list, show) — these don't represent progress.
