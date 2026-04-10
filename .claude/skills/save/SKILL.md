---
name: save
description: Save session journal with auto-detected friction and suggest trigger
argument-hint: '["message"] | :channel "message"'
---

# Save Session

Create a session journal in `.self/channels/`. Includes both human and
auto-detected observations. Checks friction thresholds and triggers
`/suggest proven` when patterns have accumulated enough evidence.

## Multi-Agent Architecture

Sessions are stored in **shared** `.self/channels/` (visible to all agents):
- Your session will be immediately visible to other agents
- No git push needed for local session visibility
- Use `--remote` with `/sync push` to share to distributed agents

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. Channel (if starts with ":"):
   - ":X" or ":X " -> channel=X, consume
   - else -> channel=current (from .self/agents/{id}/.current)

2. Title (remaining text):
   - If empty -> auto-generate from conversation
   - If present -> use as session title
```

**Parse examples:**
```
""                        -> (current channel, auto-title)
"auth refactor"           -> (current channel, "auth refactor")
":pipeline"               -> (pipeline channel, auto-title)
":pipeline auth work"     -> (pipeline channel, "auth work")
```

---

## Step 1: Gather Session Context

Analyze current conversation for:
- What was the main goal?
- What was accomplished?
- What decisions were made?
- What files were modified?
- What remains to do?
- Any dead ends or failed approaches?

## Step 2: Collect All Observations

Merge observations from **both** sources into the session journal:

### A. Auto-detected observations (from ObservationHook)

Query the observation stream for this session's auto-detected entries:
```bash
slf memory query observations --tag auto-detected --channel $CHANNEL --since $SESSION_START
```

These include:
- **friction**: search-thrashing, error-retry, backtracking, etc.
- **progress**: skill completions (save, decide, prm, validate)
- **error**: skill failures

### B. Human observations (from /note)

Query human-tagged observations:
```bash
slf memory query observations --tag human --channel $CHANNEL --since $SESSION_START
```

Also read `.prm/staged-notes.md` if it exists (legacy staging area).

### C. Conversation friction (retrospective)

Additionally analyze the conversation itself for patterns the hook
couldn't catch (these happen between skill invocations):

| Pattern | Friction Type |
|---------|---------------|
| Same tool 3+ times on similar targets | Search thrashing |
| "wait", "actually", "let me try" | Backtracking |
| Error -> retry -> success | Silent friction |
| Multi-step for simple goal | Missing automation |
| User corrected interpretation 2+ times | Clarification loop |

Stage any new friction found as observations before committing:
```bash
slf memory observe "$PATTERN" --tag friction --tag retrospective --channel $CHANNEL
```

## Step 3: Find Parent Session

- Read current channel via `slf channel current -q` (default: "main")
- List `.self/channels/<channel>/*.md`, find most recent
- This becomes `parent:` link

## Step 4: Create Session Journal

Filename: `.self/channels/<channel>/YYYY-MM-DD_<title-slug>.md`

```markdown
# <Title> - <Date>

parent: <previous-session.md or "none">
timestamp: <HH:MM>

## Context
[Situation at session start]

## Goals
- [x] Completed goal 1
- [ ] Incomplete goal (why)

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| ... | ... |

## Changes
| File | Change |
|------|--------|
| path/file | what changed |

## Observations

### Auto-Detected
[Observations from ObservationHook -- friction, progress, errors]

- [14:30] [friction] search-thrashing: docs called 3x in 45s
- [14:20] [progress] validate completed -- stage3 outputs
- [14:15] [error] sync failed -- FileNotFoundError

### Human Notes
[Observations from /note -- insights, ideas, context]

- [14:28] friction: grep 5x for same pattern
- [14:10] idea: automate test data generation

### Retrospective Friction
[Patterns detected from conversation analysis at save time]

- backtracking: tried hooks approach, reverted to polling
- clarification-loop: user corrected metric interpretation 2x

## Friction Summary

| Type | Count | Source |
|------|-------|--------|
| search-thrashing | 2 | auto + retrospective |
| error-retry | 1 | auto |
| backtracking | 1 | retrospective |
| Total | 4 | |

## Key Learnings
- [Insight]

## Open Questions
- [Unresolved items]
```

## Step 5: Clear Staging

Delete or empty `.prm/staged-notes.md`.

## Step 7: Prompt for Goal Updates

After saving, ask:

```markdown
## Session Saved

**Journal**: `.self/channels/<channel>/YYYY-MM-DD_title.md`
**Accomplishments**: N goals completed
**Observations**: X auto-detected, Y human, Z retrospective

### Update Goals?

Based on this session:
- Completed: [goals that appear done]
- New: [potential new goals identified]

Mark any complete? Add new goals?
- `/prm` to update objectives (mark complete or add new)
- Enter to skip
```

## Step 8: Update State Baseline

Run: `slf state sync`

This updates `.self/.sync-state.json` to include the newly created session.
The next agent's `/sync` will see this session in the baseline.

## Step 8b: Emit Progress Observation

Record that `/save` completed so other skills and agents can see it:

```bash
CHANNEL=$(slf channel current -q)
slf memory observe "progress: save completed -- session journal committed to $CHANNEL" \
  -t auto-detected -t progress -t "skill:save" \
  -c "$CHANNEL"
echo "{\"skill\":\"save\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"error\":false}" \
  >> .self/cache/session_traces.jsonl
```

If the journal write failed earlier, emit an error instead:
```bash
slf memory observe "error: save failed -- $REASON" \
  -t auto-detected -t error -t "skill:save" \
  -c "$CHANNEL"
echo "{\"skill\":\"save\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"error\":true}" \
  >> .self/cache/session_traces.jsonl
```

## Step 9: State Consistency Check + Objective Alignment

Run `/sync check` silently after goal prompt. Additionally, check if completed work correlates with PRM objectives.

### Objective Alignment Check

```python
from extensions.memory.change_digest import check_objective_alignment

signals = check_objective_alignment(channel=current_channel)

# Filter to medium+ confidence signals
strong_signals = [s for s in signals if s.confidence in ("strong", "medium")]
```

If alignment signals found, display them:

```markdown
### Objective Alignment Signals

Based on your work this session, these objectives may be complete:

| Objective | Evidence | Confidence |
|-----------|----------|------------|
| "implement auth" | src/auth/ modified, 3 commits, session title matches | strong |
| "add caching" | 2 commits mention cache, cache.py created | medium |

Mark any complete?
- `/prm` to update objectives (recommended for strong evidence)
- Enter to skip
```

**Confidence levels:**
- **strong**: Keyword match in objective + git files + session confirmation → safe to mark
- **medium**: Keyword match + either git OR session → review before marking
- **weak**: Loose association → informational only (not shown to avoid noise)

### Staleness Checks

| File | Check | Stale If |
|------|-------|----------|
| status.md | Last Updated | >7 days old |
| status.md | Phase vs work | Session work suggests phase change |
| status.md | Blockers | Blocker resolved during session |
| objectives.md | Completion | Objective work done, not marked (from alignment) |
| decisions.md | Logging | Major decision made, not logged |

### If Issues Found

```markdown
### State Drift Detected

| File | Issue | Suggested Fix |
|------|-------|---------------|
| status.md | Last Updated stale (10 days) | Auto-update to today |
| status.md | Phase may be stale | `/status phase "Testing"` |
| objectives.md | Work completed | `/prm` to mark objective done |

Apply auto-fixes? (runs `/sync fix`)
- **y**: Apply safe fixes, prompt for others
- **n**: Skip (can run `/sync fix` later)
```

### If No Issues

Skip silently (no output).

---

## Step 10: Friction Threshold Check -> Auto-Suggest Trigger

**This is the autopoietic trigger.** After saving the session, check whether
accumulated friction patterns across recent sessions have crossed the
threshold for structural self-modification.

### How It Works

1. Analyze friction observations from the last 14 days on this channel
2. Group by normalized pattern key
3. Compare occurrence counts against thresholds (default: 3)
4. If any pattern crosses threshold, present a suggestion prompt

### Thresholds (configurable in `.self/config/settings.json`)

```json
{
  "friction_thresholds": {
    "search-thrashing": 3,
    "error-retry": 3,
    "repeated-read": 3,
    "backtracking": 2,
    "slow-execution": 3,
    "default": 3
  }
}
```

### If Threshold Reached

```markdown
### Friction Threshold Reached

**3 pattern(s)** have crossed the suggestion threshold across recent sessions:

- **search-thrashing:grep** (5x, last: 02-08) -> CLAUDE.md
  Example: "search-thrashing: grep called 4x in 30s -- args: auth handler"
- **error-retry:validate** (3x, last: 02-07) -> CLAUDE.md
  Example: "error-retry: validate failed then succeeded -- error was: FileNotFoundError"
- **backtracking:sync** (2x, last: 02-08) -> CLAUDE.md or skill refinement
  Example: "backtracking: sync -> docs -> sync (returned to previous approach)"

Run `/suggest proven` to generate structural proposals from these patterns.
Or skip -- patterns will remain for next check.
```

### If Below Threshold

Skip silently (no output).

### What This Enables

The project's structure evolves from accumulated experience:

```
/note + ObservationHook -> observations.jsonl
    -> /save commits to session journal
        -> friction accumulates across sessions
            -> threshold reached
                -> /suggest proven proposes structural change
                    -> human approves
                        -> .self/ structure modified
                            -> project has learned from its friction
```

This is the reflexive loop closed: observe -> accumulate -> propose -> modify.
The human approves but doesn't drive.

---

## Output

```markdown
## Session Saved

**Journal**: `.self/channels/main/2026-01-28_auth-refactor.md`
**Parent**: 2026-01-28_morning.md
**Channel**: main

### Summary
- Goals completed: 2/3
- Decisions logged: 3
- Observations: 8 auto-detected, 3 human, 2 retrospective

### Friction Summary
| Type | Count |
|------|-------|
| search-thrashing | 3 |
| error-retry | 2 |
| backtracking | 1 |

### Tasks Spawned
- bd-xxx: Follow-up task

### Goal Updates?
Completed work suggests these goals may be done:
- "Implement auth flow" - mark complete?

Run `/prm` to update objectives, or skip.

### State Consistency
1 issue detected:
- status.md Last Updated stale (8 days)

Apply auto-fix? (y/n)

### Friction Threshold Reached
**2 pattern(s)** ready for structural proposals:
- **search-thrashing:grep** (5x) -> CLAUDE.md
- **error-retry:validate** (3x) -> CLAUDE.md

Run `/suggest proven` to generate proposals, or skip.
```

---

## Quiet Output

```
-> .self/channels/main/2026-01-28_auth-refactor.md
  goals: 2/3 | decisions: 3 | obs: 8a+3h+2r | friction: 6 | bd+: 1
  state: 1 issue | threshold: 2 patterns ready
```

---

## Constraints

- Be concise but complete
- Focus on handoff value
- **Include both auto-detected and human observations** in journal
- **Actively detect retrospective friction** from conversation
- Note dead ends (saves future time)
- Always link to parent session
- Clear staging after commit
- Prompt for goal updates (don't auto-modify objectives)
- **Check friction thresholds** and surface when ready for /suggest
