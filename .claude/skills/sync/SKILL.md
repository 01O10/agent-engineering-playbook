---
name: sync
description: Bootstrap context for new conversation - multi-agent aware
argument-hint: '[:channel] [check|fix] [--deep] [--remote]'
---

# Sync Context

Load project state for a new agent conversation. Reads CLAUDE.md, `.self/`, `.prm/`, and session history.

Use at conversation start to get oriented, or mid-conversation with `check` to verify alignment.

## Multi-Agent Architecture

This skill is multi-agent aware:
- **Per-agent state**: Each agent has its own `.current` in `.self/agents/{id}/`
- **Shared sessions**: Sessions in `.self/channels/` are visible to all agents
- **Channel inheritance**: Sync includes inherited channels (see config.yaml)
- **Remote sync**: Use `--remote` to pull/push via git branch

**Automatic behavior**: The session-start hook runs `/sync pull` automatically, so you don't need to manually sync at conversation start.

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. Channel (if starts with ":"):
   - ":X" → channel=X
   - else → channel=current (from .self/agents/{id}/.current)

2. Mode:
   - "check" → detect drift and staleness
   - "check --deep" → staleness + semantic validation of PRM claims
   - "fix" → auto-apply detected fixes
   - "--deep" → bootstrap + run semantic validation
   - (default) → bootstrap context
```

**Parse examples:**
```
""                    → sync with current channel
":pipeline"           → sync with pipeline channel context
"check"               → detect drift and staleness (fast)
"check --deep"        → staleness + semantic validation
"fix"                 → auto-apply fixes
"--deep"              → bootstrap + validate PRM claims
":pipeline check"     → check on pipeline channel
":pipeline check --deep" → deep check on pipeline channel
```

---

## Default Mode: Bootstrap Context

**Note**: Agent isolation (worktree) and state baseline are handled automatically by the session-start hook. This skill focuses on loading context.

Load context in order:

### 1. Project Rules (CLAUDE.md)

Read `.claude/CLAUDE.md` for:
- Session start/end procedures
- Git rules (commits, hooks)
- Available skills and their purposes
- Rules by task type (links to `.claude/rules/`)

**Key sections to note:**
- Session Start instructions
- Git safety rules
- Skill table

### 2. Project Identity (`.self/`)

Read `.self/prm/status.md` for:
- Current sprint/focus
- Active blockers
- Recent progress

### 3. Project State (`.prm/`)

Read:
- `.prm/objectives.md` - active goals
- `.prm/decisions.md` - recent decisions (last 5)
- `.prm/constraints.md` - key constraints

### 4. Domain Context

Summarize `.domain/`:
- Term count from glossary.md
- Rule count from rules.md
- Key validity ranges

### 5. Session Context

Read `.self/agents/{id}/.current` for channel (or `slf channel current -q`), then:
- List recent sessions in channel (last 5) from `.self/channels/`
- Read `.prm/staged-notes.md` for pending observations
- If channel != main and inherits from main, also summarize main channel

### 5.5. Probe State (auto-init if missing)

Check whether the knowledge probe is initialized:

```bash
if [ ! -f ".self/tiers/probe.yaml" ] || [ ! -f "tier_checks.py" ]; then
    slf probe init
fi
```

If probe was just initialized, note it in the output:
```
Probe: initialized (30 files tracked, run `slf probe status -v` for details)
```

If probe already exists, show a one-liner:
```bash
slf tiers status  # → "source: authoritative | knowledge: verified | 0 cascades"
```

### 5.6. Change Digest (if baseline exists)

If a sync state baseline exists (`.self/.sync-state.json`), generate and display the change digest to understand what has changed since last sync.

```python
from extensions.memory.change_digest import build_change_digest

digest = build_change_digest(
    channel=current_channel,
    since=None,  # Automatically uses last sync timestamp
)

if digest.since:  # Only if we have a baseline to compare
    print(digest.format_for_sync())
```

The digest shows:
- **Git activity**: Commits since last sync, files changed by area
- **Observations**: Accumulated observations (friction, progress, errors)
  - **Includes loop-emitted observations** tagged with `loop:locked` or `loop`
  - This makes work from automated loops visible to interactive sessions
- **Other agents' work**: Sessions posted, decisions made by other agents
- **PRM changes**: Objectives added/completed, status phase changes, new decisions
- **Knowledge staleness**: Stale knowledge docs (hash mismatch), high-drift artifacts (when `include_knowledge=True`)
- **Objective alignment signals**: Potential objective completions detected from work patterns

If no baseline exists (first sync), skip the digest—nothing to compare against.

**Example Output:**

```markdown
## Change Digest

*Changes since 2026-02-09 08:30*

### Git Activity
**5 commits**

- `a3f7e12` feat(digest): add change digest module
- `b4c8d3a` feat(cli): register digest commands
- `c5d9e4b` docs(sync): add change digest section
  _(+2 more)_

**Files changed by area:**
- extensions: 3 files
- config: 2 files
- tooling: 1 file

### Observations
**8 accumulated**

By type:
- friction: 3
- progress: 4
- loop: 1

Examples:
- friction: search-thrashing in codebase exploration
- progress: loop completed 5 tasks
- progress: task bd-123 implemented

### Other Agents' Work
**2 sessions** by 1 agents

- 2026-02-09: Background loop execution (agent-loop-01)
- 2026-02-08: Feature implementation (agent-cadd-02)

### PRM Changes
**Objectives completed:** 1
- implement change digest

**Decisions added:** 2

### Knowledge Staleness
**5 docs**: 4 OK, 1 stale, 0 new, 0 untracked

**Stale documents** (hash mismatch):
- drift_scorer.md
```

The Knowledge Staleness section appears when `include_knowledge=True` is passed to `build_change_digest()`. Use this in `/sync check` mode or when explicitly requested. Default `/sync` bootstrap omits it for speed.

This digest provides immediate context about what happened since you last synced, making it easy to pick up where work left off or understand what automated loops accomplished.

---

## Check Mode: Verify Alignment & Staleness

Use mid-conversation to detect drift between agent state and filesystem, AND detect stale state across .prm/ files.

### Checks Performed

| Check | What it detects | Stale If |
|-------|-----------------|----------|
| Channel validity | `.current` points to existing directory | Directory missing |
| Channel format | `.current` has proper format | Empty, whitespace, or invalid |
| CLAUDE.md drift | Rules or skills changed | File modified since sync |
| Status drift | `.self/prm/status.md` changed since sync | >7 days old |
| Status phase | Phase vs sprint.json alignment | All tasks done but phase not updated |
| Status blockers | Blocker references valid | Blocker references closed task |
| Objective drift | `.prm/objectives.md` modified externally | Work done but objective not marked |
| Decision drift | New decisions logged | Major choice made, not logged |
| Session drift | New sessions added to channel | File modified |
| Staged notes | Notes added externally | File modified |

### How It Works

1. **Read state baseline** (if exists):
   - Run `slf state check --json`
   - This compares against `.self/.sync-state.json` (shared baseline)
   - Not conversation memory - actual persisted state
2. **Validate channel**:
   - Read `.sessions/.current`
   - Verify directory `.sessions/<channel>/` exists
   - Check format (single line, trimmed, no special chars)
3. Read current filesystem state
4. Compare against baseline state (not conversation memory)
5. Check for staleness conditions (outdated dates, misaligned state)
6. Report misalignments and staleness
7. Suggest fixes or re-sync

### Channel Validation

```bash
# Read and validate current channel (multi-agent aware)
CHANNEL=$(slf channel current -q 2>/dev/null)
if [ -z "$CHANNEL" ]; then
  echo "ERROR: No current channel"
else
  # Check in new .self/channels/ or legacy .self/sessions/
  if [ -d ".self/channels/$CHANNEL" ] || [ -d ".self/sessions/$CHANNEL" ]; then
    echo "Channel: $CHANNEL (valid)"
  else
    echo "ERROR: Channel directory does not exist"
  fi
fi
```

### Check Output

```markdown
## State Consistency Check

**Status**: 2 issues found

| File | Issue | Suggested Action |
|------|-------|------------------|
| status.md | Last Updated >7 days | Update date or run `/status` |
| status.md | Phase stale (all sprint tasks done) | `/status phase "Sprint Complete"` |
| status.md | Blocker resolved (bd-123 closed) | `/status blocker clear` |
| objectives.md | Objective work done, not marked | `/goal done "..."` |

### Drift Report

| Area | Status | Details |
|------|--------|---------|
| .current | OK | Channel: main (valid) |
| CLAUDE.md | OK | No changes |
| status.md | STALE | Last Updated: 2026-01-20 (11 days ago) |
| objectives.md | OK | No changes |
| decisions.md | DRIFT | 1 new decision added |
| sessions/ | DRIFT | 2 new sessions in main |
| staged-notes | OK | No changes |

### Recommendation

Run suggested commands or `/sync fix` to auto-apply fixes.
```

### No Issues Output

```markdown
## State Consistency Check

**Status**: ALIGNED

No issues detected. State is current and consistent.
```

---

## Fix Mode: Auto-Apply Fixes

Use `/sync fix` to automatically apply detected fixes.

### How It Works

1. Run `/sync check` to detect issues
2. For each fixable issue, show proposed fix
3. Apply all fixes or prompt per-fix
4. Update Last Updated dates where appropriate

### Fixable Issues

| Issue | Auto-Fix |
|-------|----------|
| status.md Last Updated stale | Update to today's date |
| Blocker references closed task | Remove blocker |
| Phase stale (all tasks done) | Suggest phase update (prompt) |
| Objective work complete | Mark objective done (prompt) |

### Fix Output

```markdown
## State Fixes Applied

**Fixed**: 2 issues
**Prompted**: 1 issue (needs confirmation)

| Fix | Status |
|-----|--------|
| status.md Last Updated → 2026-01-31 | ✓ Applied |
| Removed stale blocker (bd-123) | ✓ Applied |
| Phase update: "Implementation" → "Testing" | ? Confirm: `/status phase "Testing"` |

Files modified: status.md
```

### When Fix Requires Confirmation

Some fixes require explicit confirmation:
- Phase changes (user should verify correctness)
- Objective completion (user should verify work is done)
- Decision logging (user should provide rationale)

For these, `/sync fix` outputs the suggested command instead of applying.

---

## Deep Mode: Semantic Validation

Use `--deep` to validate that PRM claims match the actual codebase. Detects drift where files are unchanged but claims are stale.

### What Deep Mode Validates

| Category | Example Claim | Validation |
|----------|---------------|------------|
| Objectives checkmarks | `[x] z_to_0_100() implemented` | grep for function definition |
| Numerical claims | `24 behavioral tests` | count test_* functions |
| Context counts | `17 validation contexts` | count CONTEXTS entries |
| File paths | `src/analysis_helpers.py` | stat file exists |
| Config claims | `weight_scheme: equal` | read config/defaults.yaml |

### How It Works

1. Parse `.self/prm/objectives.md` for `[x]` items
2. Parse `.self/prm/status.md` for file paths
3. Parse `.self/prm/decisions.md` for config assertions
4. Extract numerical claims (regex for digits + "tests", "contexts", etc.)
5. Run semantic checks against codebase via `.self/bin/validate-prm.py`
6. Report misalignments

Run validation script directly:
```bash
python .self/bin/validate-prm.py
python .self/bin/validate-prm.py --json  # Machine-readable
python .self/bin/validate-prm.py --verbose  # Extra details
```

### Deep Check Output

```markdown
## Deep Validation Report

### Objectives (objectives.md)
| Claim | Status | Details |
|-------|--------|---------|
| z_to_0_100 implemented | ✅ | Found in src/analysis_helpers.py:45 |
| 24 behavioral tests | ⚠️ | Found 22, expected 24 |
| 17 validation contexts | ✅ | Matches VALIDATION_CONTEXTS |

### File Paths (status.md)
| Path | Status |
|------|--------|
| src/analysis_helpers.py | ✅ Exists |
| tests/test_validation_framework.py | ✅ Exists |

### Config Claims (decisions.md)
| Config | Claimed | Actual | Status |
|--------|---------|--------|--------|
| weight_scheme | equal | equal | ✅ |
| scale_0_100 | false | false | ✅ |

### Summary
- **Total checks**: 15
- **Passed**: 14
- **Warnings**: 1 (test count mismatch)
- **Failures**: 0
```

### Behavior by Flag

| Command | Behavior |
|---------|----------|
| `/sync check` | File mtime drift + staleness (fast) |
| `/sync check --deep` | Staleness + semantic validation |
| `/sync --deep` | Bootstrap context + run validation + suggest fixes |
| `/sync fix` | Auto-apply staleness fixes (not semantic) |

---

## Default Output

```markdown
## Project Context

### Rules (CLAUDE.md)
- Session start: read status.md
- Git: new commits only (no amend/force unless requested)
- Skills: /sync, /save, /note, /goal, /decide, /suggest, /channel, /validate

### Status
**Focus**: Sprint 2026-01-30 - Skill simplification
**Blockers**: None
**Last update**: 2026-01-28

### Objectives (Active)
- [ ] Simplify skill commands (28 → 8)
- [ ] Add channel support for sessions

### Recent Decisions
| Date | Decision |
|------|----------|
| 01-28 | Use JWT for auth |
| 01-27 | Binomial test for SIC |
| 01-25 | PostgreSQL over MongoDB |

### Domain
Terms: 45 | Rules: 12 | Validity checks: 8

### Session Context

**Channel**: main (5 sessions)
**Last**: 2026-01-28 auth-refactor

| Date | Session | Decisions | Friction |
|------|---------|-----------|----------|
| 01-28 | auth-refactor | 3 | 2 |
| 01-28 | morning | 1 | 0 |
| 01-27 | pipeline-fix | 2 | 1 |

**Staged Notes**: 2 pending
- friction: grep 5x for pattern
- idea: automate test data

**Other Channels**: pipeline (2), infra (1)

---

Ready to work. Use `/goal` for objectives, `/save` when done.
```

---

## Quiet Output

Default:
```
rules: session→status.md | git→new commits | skills: 8
status: Sprint 01-30 (skill simplification) | no blockers
goals: 3 active | decisions: 15 total
domain: 45 terms, 12 rules
channel: main (5 sessions) | staged: 2
bd: 2 ready, 0 stale
```

Check (aligned):
```
check: ALIGNED | synced 5 min ago
```

Check (drifted):
```
check: DRIFT | status.md, decisions.md, 2 sessions
recommend: /sync to reload
```

---

## Muted State

If `.sessions/.muted` exists:

```markdown
## Project Context [MUTED]

**Note**: Session tracking paused. Use `/channel unmute` to resume.

[rest of context]
```

---

## Use Cases

| When | Use |
|------|-----|
| Starting new conversation | `/sync` |
| Switching to channel work | `/sync :pipeline` |
| After long break | `/sync` to re-orient |
| Before major work | `/sync` to check blockers |
| Mid-conversation sanity check | `/sync check` |
| Suspect external changes | `/sync check` |
| After completing work | `/sync check` to detect stale state |
| Stale state detected | `/sync fix` to auto-apply fixes |
| Before ending session | `/sync check` (or use `/save` which includes this) |
| After major code changes | `/sync check --deep` to verify PRM accuracy |
| Suspect stale documentation | `/sync --deep` for full validation |

---

## Relationship to Other Commands

| Command | Purpose |
|---------|---------|
| `/sync` | Read context (new conversation) |
| `/sync check` | Verify alignment and detect staleness |
| `/sync fix` | Auto-apply detected fixes |
| `/save` | Write context (includes consistency check) |
| `/goal` | Modify objectives |
| `/decide` | Log decisions |
| `/status` | Update status.md |

---

## Constraints

- Default mode is read-only (bootstrap context)
- Check mode is read-only (detect issues)
- Fix mode modifies files (status.md, objectives.md)
- Designed for conversation start (or mid-check)
- Loads full project context, not just sessions
- Shows other channels for context
- Check mode compares against "last known" state
- Fix mode only auto-applies safe fixes; prompts for others
