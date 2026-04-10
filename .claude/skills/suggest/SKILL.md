---
name: suggest
description: Analyze workflow and propose improvements
argument-hint: '[fresh | proven] [quiet]'
---

# Workflow Improvement

Analyze session journals and friction logs to propose workflow improvements.

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. Mode:
   - "fresh" → analyze current session only
   - "proven" → bake patterns with 2+ occurrences
   - default → analyze accumulated logs

2. Flags:
   - "quiet" → terse output
```

**Parse examples:**
```
""              → analyze logs, propose improvements
"fresh"         → analyze current session only
"proven"        → bake proven patterns into structure
"quiet"         → terse output
"fresh quiet"   → current session, terse
```

---

## Default Mode: Analyze & Propose

### Sources

- `.sessions/<channel>/` - session journals
- `.prm/friction-log.md` - accumulated friction

### Analysis

1. Read sources
2. Identify friction patterns (frequency, impact)
3. Generate max 3 proposals

### Proposal Format

```markdown
## Workflow Improvement

**Source**: logs (5 sessions, 12 friction entries)

### Proposal 1: [Type] - [Name]

**Solves**: [friction point]
**Evidence**: [pattern count and source]
**Impact**: [low|medium|high]
**Effort**: [low|medium|high]

**Implementation**:
```
[proposed content]
```

### Proposal 2: ...

### Proposal 3: ...

---

**Accept which?** [1/2/3/a/n]
```

---

## Fresh Mode

Analyze current conversation only. Ignore accumulated logs.

- Do NOT read `.sessions/`
- Do NOT read `.prm/friction-log.md`
- Analyze patterns in THIS session
- Useful for immediate insights

### Output

```markdown
## Workflow Improvement (Fresh)

**Source**: current session only

### Observed Patterns
- Search thrashing: 4 instances
- Backtracking: 2 instances

### Proposals
[Same format as default]
```

---

## Proven Mode (Bake)

Bake patterns with 2+ occurrences into permanent structure.

### Pattern → Structure Mapping

| Pattern | Bakes Into | Threshold |
|---------|------------|-----------|
| Behavioral rule | `CLAUDE.md` | 2+ |
| Domain knowledge | `.domain/*.md` | 2+ |
| Constraints | `.prm/constraints.md` | 2+ |
| Action sequence | `/skill` (HIGH BAR) | 3+ |
| Delegation pattern | `.claude/agents/` | 3+ |

### Skill Proposal Criteria (HIGH BAR)

New skills require ALL:
- 3+ occurrences of exact same sequence
- 3+ steps in sequence (not trivial)
- Parameterizable
- Distinct from existing skills
- User explicitly approves

**Most patterns → CLAUDE.md or .domain/, not skills.**

### Behavior

1. Identify patterns with 2+ occurrences
2. For each:
   - Classify type
   - Draft proposed structure
   - Show for approval
3. Create approved structures
4. Archive processed sessions
5. Clear friction log entries

### Output

```markdown
## Bake Proven Patterns

**Patterns found**: 4 (2+ occurrences)

### Pattern 1: [Type] - [Name]

**Frequency**: 3 occurrences across 2 sessions
**Source sessions**: [list]

**Proposed structure**:
```
[content]
```

**Accept?** [y/n]

### Pattern 2: ...

---

## Bake Summary

| Pattern | Type | Created |
|---------|------|---------|
| test-before-commit | CLAUDE.md | added |
| validity-check | domain | .domain/validity.md |

**Archived**: 3 sessions
**Remaining**: 1 pattern (needs more occurrences)
```

---

## Quiet Output

Default:
```
src: logs (5 sessions) | bd: 3 open, 1 stale

P1: workflow test-first → CLAUDE.md | H/L
P2: skill grep-pattern → .claude/skills/ | M/M
P3: domain metric-range → .domain/ | M/L

[1/2/3/a/n]?
```

Fresh:
```
src: fresh | patterns: 4 (search: 2, backtrack: 2)

P1: ...
```

Proven:
```
proven: 4 patterns

P1: workflow test-first → CLAUDE.md [y/n]?
P2: domain validity → .domain/ [y/n]?
---
baked: 2 | archived: 3 | remaining: 1
```

---

## Constraints

- Max 3 proposals per run
- Show evidence for each proposal
- Default to `focus` mode (evidence-based)
- Skills have HIGH BAR (3+ occurrences, 3+ steps)
- Announce source mode
