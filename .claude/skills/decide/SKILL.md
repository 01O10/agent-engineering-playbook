---
name: decide
description: Log architectural decision (ADR)
argument-hint: '"decision" "rationale"'
---

# Log Decision

Log an architectural decision record (ADR) to `.self/prm/decisions.jsonl`.

## Multi-Agent Architecture

Decisions are stored in **append-only JSONL** format for merge-friendly multi-agent storage:
- Each decision is a single JSON line with timestamp, agent ID, decision, rationale
- No merge conflicts when multiple agents log decisions
- All agents see each other's decisions immediately

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. First quoted string → decision
2. Second quoted string → rationale
3. Optional: "context:" prefix for additional context
```

**Parse examples:**
```
"Use JWT" "stateless"                    → decision + rationale
"Use binomial test" "adapts to n"        → decision + rationale
context: "auth choice" "Use JWT" "stateless" → with context
```

---

## Behavior

### Step 1: Parse Arguments

Parse decision and rationale from arguments. If missing rationale, ask for it.

### Step 1.5: Check Related Decisions

Before logging, check for related past decisions to ensure consistency:

```python
from extensions.memory.decision_context import find_related_decisions, format_related_decisions

related = find_related_decisions(decision_text, channel=current_channel)

if related:
    print(format_related_decisions(related))
    print("\n### Questions to Consider:")
    print("- Does this decision **supersede** any past decision?")
    print("- Does it **extend** a past decision?")
    print("- Does it **conflict** with a past decision?")
    print("\nIf yes, note the relationship in rationale or context.")
```

**Example output:**

```markdown
### Related Decisions

**1. Use MongoDB for database** (2026-01-15)
   Chosen for flexible schema and horizontal scaling
   Tags: database, architecture

**2. PostgreSQL over MongoDB** (2026-01-25)
   Switched due to strong consistency requirements
   Tags: database

### Questions to Consider:
- Does this decision **supersede** any past decision?
- Does it **extend** a past decision?
- Does it **conflict** with a past decision?

If yes, note the relationship in rationale or context.
```

This prevents accidentally making conflicting decisions and helps maintain architectural consistency.

### Step 2: Log Decision

Append to `.self/prm/decisions.jsonl`:

```json
{"ts": "2026-01-28T14:30:00Z", "agent": "swift-falcon", "decision": "<decision>", "rationale": "<rationale>", "context": "<context>"}
```

### Step 3: Emit Progress Observation

Record that `/decide` completed:

```bash
CHANNEL=$(slf channel current -q)
slf memory observe "progress: decide completed -- logged '$DECISION'" \
  -t auto-detected -t progress -t "skill:decide" \
  -c "$CHANNEL"
echo "{\"skill\":\"decide\",\"args\":\"$DECISION\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"error\":false}" \
  >> .self/cache/session_traces.jsonl
```

If decision logging failed, emit an error:
```bash
slf memory observe "error: decide failed -- $REASON" \
  -t auto-detected -t error -t "skill:decide" \
  -c "$CHANNEL"
echo "{\"skill\":\"decide\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"error\":true}" \
  >> .self/cache/session_traces.jsonl
```

---

## Output

```markdown
## Decision Logged

**Decision**: Use JWT for authentication
**Rationale**: Stateless, scales horizontally
**Date**: 2026-01-28

### Recent Decisions
| Date | Decision |
|------|----------|
| 01-28 | Use JWT for authentication |
| 01-27 | Binomial test for SIC |
| 01-25 | PostgreSQL over MongoDB |

View all: `.self/prm/decisions.jsonl`
```

---

## Storage Format

`.self/prm/decisions.jsonl` (append-only JSONL):
```jsonl
{"ts": "2026-01-28T14:30:00Z", "agent": "swift-falcon", "decision": "Use JWT for authentication", "rationale": "Stateless, scales horizontally", "context": "auth mechanism for API"}
{"ts": "2026-01-27T10:15:00Z", "agent": "keen-robin", "decision": "Use binomial test for SIC", "rationale": "Adapts to sample size", "context": "statistical test choice"}
```

Each line is a self-contained JSON object with:
- `ts`: ISO timestamp
- `agent`: Agent ID that made the decision
- `decision`: What was decided
- `rationale`: Why it was decided
- `context`: Optional background

---

## Decision vs Goal

| `/goal` | `/decide` |
|---------|-----------|
| WHAT to achieve | HOW we chose |
| Mutable (add, complete, drop) | Immutable (historical record) |
| Future-focused | Past-focused |
| Objectives | Architecture Decision Records |

---

## Quiet Output

```
logged: "Use JWT" (01-28) | 15 total decisions
```

---

## Constraints

- Decisions are immutable (append-only)
- Always require rationale
- Date-stamp all entries
- Brief consequences (can be inferred)
- Reference in session journals
