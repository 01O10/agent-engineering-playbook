---
name: domain
description: Manage domain knowledge - terms, rules, entities, validity ranges
argument-hint: '[term | rule | entity | validity] [action] [args]'
---

# Domain Knowledge Management

Consolidated management of `.self/domain/` files.

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. No args → show domain files overview
2. "term" → glossary management
3. "rule" → domain rules management
4. "entity" → entity management
5. "validity" → validity ranges management
```

**Parse examples:**
```
""                              → show all domain files overview
"term"                          → list glossary terms
"term add SRM 'Standardized Response Mean'" → add term
"rule"                          → list domain rules
"rule add 'ICC > 0.7 acceptable'" → add rule
"entity"                        → list entities
"entity add Feature 'Measurable biomarker'" → add entity
"validity"                      → list validity ranges
"validity add ICC 0 1 ratio"    → add validity range
```

---

## Subcommand: Overview (default)

Show all domain files:

```markdown
## Domain Files (.self/domain/)

  ✓ glossary.md (32 lines)
  ✓ rules.md (45 lines)
  ✓ entities.md (28 lines)
  ✓ validity.md (19 lines)

Commands: slf domain term | rule | entity | validity
```

---

## Subcommand: `term`

Manage glossary terms in `glossary.md`.

### `term` (list)
```markdown
## Glossary Terms

  **SRM**: Standardized Response Mean
  **ICC**: Intraclass Correlation Coefficient
  **LME**: Linear Mixed Effects model
```

### `term add "name" "definition"`
```markdown
Added term: SRM = Standardized Response Mean
```

---

## Subcommand: `rule`

Manage domain rules in `rules.md`.

### `rule` (list)
```markdown
## Domain Rules

  1. ICC > 0.7 is acceptable reliability
  2. SRM uses pooled SD, not individual SD
  3. p < 0.05 for statistical significance
```

### `rule add "text"`
```markdown
Added rule: ICC > 0.7 is acceptable reliability
```

---

## Subcommand: `entity`

Manage domain entities in `entities.md`.

### `entity` (list)
```markdown
## Domain Entities

  **Feature**: A measurable biomarker extracted from sensor data
  **Composite**: Weighted combination of multiple features
  **Visit**: Single patient measurement session
```

### `entity add "name" "description"`
```markdown
Added entity: Feature
```

---

## Subcommand: `validity`

Manage validity ranges in `validity.md`.

### `validity` (list)
```markdown
## Validity Ranges

  ICC: 0 - 1 ratio
  SRM: -5 - 5 effect_size
  p_value: 0 - 1 probability
```

### `validity add "field" min max "unit"`
```markdown
Added validity range: ICC (0 - 1 ratio)
```

---

## File Locations

| File | Content |
|------|---------|
| `.self/domain/glossary.md` | Domain terms and abbreviations |
| `.self/domain/rules.md` | Computation logic, thresholds, formulas |
| `.self/domain/entities.md` | Domain objects and relationships |
| `.self/domain/validity.md` | Expected ranges, red flags |

---

## CLI Equivalent

```bash
slf domain                            # overview
slf domain term list                  # list terms
slf domain term add "X" "definition"  # add term
slf domain rule list                  # list rules
slf domain rule add "X"               # add rule
slf domain entity list                # list entities
slf domain entity add "X" "desc"      # add entity
slf domain validity list              # list ranges
slf domain validity add "X" 0 1 unit  # add range
```

---

## When to Read Domain Files

| File | When |
|------|------|
| `glossary.md` | Unsure about metric meaning, abbreviations |
| `rules.md` | Implementing computation, checking formulas |
| `entities.md` | Understanding data model, relationships |
| `validity.md` | Validating outputs, checking expected ranges |

---

## Integration with /validate

The `/validate` skill uses `validity.md` rules to check pipeline outputs:

```bash
python .self/bin/validate-outputs.py outputs/
```

Update validity ranges when adding new metrics or changing thresholds.

---

## Observation Emission

After any **write** subcommand completes (term add, rule add, entity add, validity add), emit an observation:

```bash
CHANNEL=$(slf channel current -q)
slf memory observe "progress: domain $SUBCOMMAND completed -- $SUMMARY" \
  -t auto-detected -t progress -t "skill:domain" \
  -c "$CHANNEL"
echo "{\"skill\":\"domain\",\"args\":\"$SUBCOMMAND\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"error\":false}" \
  >> .self/cache/session_traces.jsonl
```

On error:
```bash
slf memory observe "error: domain $SUBCOMMAND failed -- $REASON" \
  -t auto-detected -t error -t "skill:domain" \
  -c "$CHANNEL"
echo "{\"skill\":\"domain\",\"args\":\"$SUBCOMMAND\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"error\":true}" \
  >> .self/cache/session_traces.jsonl
```

**Skip observation for read-only subcommands** (overview, list) — these don't represent progress.
