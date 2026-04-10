---
name: auto
description: Autonomous agent mode — pick a role and work on objectives unsupervised
argument-hint: '[achieve|refine|validate|expand|review|status|stop] [--coordinate] [--max-cycles N]'
---

# Auto Mode

Autonomous work mode. Agent picks a role, claims objectives from PRM, executes work cycles, and saves progress. Between cycles, guardrails are checked and the agent decides whether to continue.

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. Subcommand (first word):
   - "achieve"    → role=achieve (implement next unblocked objective)
   - "refine"     → role=refine (improve recent code quality)
   - "validate"   → role=validate (run checks, flag regressions)
   - "expand"     → role=expand (fill gaps in docs/tests/knowledge)
   - "review"     → role=review (synthesize other agents' recent work)
   - "status"     → show auto session status, then stop
   - "stop"       → send stop signal to running auto agents
   - quoted text  → role=custom, description=$ARGUMENTS
   - empty        → interactive elicitation (show menu)

2. Flags (after subcommand):
   - "--coordinate" → register in manifest, create dedicated channel
   - "--max-cycles N" → override max work cycles (default: 5)
   - "--dry"       → plan only, skip execution
```

---

## Step 0: Resolve Role

### If no arguments — Interactive Elicitation

Present this menu:

```
## Auto Mode

What role should this agent fill?

  1. Achieve   — Pick next unblocked objective, implement it, save progress
  2. Refine    — Review recent work, run /suggest, apply improvements
  3. Validate  — Run checks (golden, propagation, tiers), flag regressions
  4. Expand    — Identify gaps in knowledge/docs/tests, fill them
  5. Review    — Read other agents' recent sessions, synthesize feedback
  6. Custom    — Describe your own role

Select [1-6] or describe a role:
```

Wait for user selection. Map: 1→achieve, 2→refine, 3→validate, 4→expand, 5→review, 6→ask for description.

### If subcommand is "status"

Show current auto state:
1. Read `.self/auto/manifest.json` — show active agents, roles, claims
2. Read `.self/auto/coord.jsonl` — show last 5 messages
3. Read `.self/auto/claims.jsonl` — show active claims
4. If no manifest exists: "No auto session active"

Then stop (do not enter a work cycle).

### If subcommand is "stop"

1. Create `.self/auto/stop` file
2. Post to coord.jsonl: `{"type": "stop", "target": "all"}`
3. Print confirmation

Then stop.

---

## Step 1: Initialize

1. Read current agent identity (already set by SessionStart hook)
2. Read `.self/prm/objectives.md` for active objectives
3. Read `.self/prm/status.md` for current phase/blockers

Set local state:
- `role` = resolved role from Step 0
- `cycle_count` = 0
- `max_cycles` = from --max-cycles flag or 5
- `dry_run` = from --dry flag

### If --coordinate flag is set:

1. Read or create `.self/auto/manifest.json`
2. Register this agent: role, alias, channel
3. Create dedicated channel: `auto-{role}-{alias}`
4. Switch to that channel
5. Post coord message: `{"type": "joined", "role": "...", "msg": "..."}`
6. Enter worktree: use EnterWorktree for isolation

---

## Step 2: Work Cycle

Execute ONE cycle per role, then check guardrails (Step 3).

### Role: achieve

1. **Read** active objectives from `.self/prm/objectives.md`
2. **Filter**: skip completed, skip claimed (if --coordinate: check claims.jsonl)
3. **Select** first unclaimed active objective
4. If none: print "All objectives addressed", go to Step 4
5. **Claim** (if --coordinate): append to claims.jsonl, post coord message
6. **Plan**: Read relevant files, draft implementation steps (max 10)
7. **Execute**: Follow plan using Edit/Write/Bash tools
8. **Validate**: Run relevant tests
9. **Commit**: Stage specific files, commit with `auto(achieve): objective #N`
10. **Release** (if --coordinate): update claims.jsonl, post coord message

### Role: refine

1. **Read** recent git log (last 10 commits) and changed files
2. **Analyze** code quality in recently modified files
3. **Select** top improvement (highest impact, lowest risk)
4. **Execute** improvement in isolation
5. **Test** to confirm no regressions
6. **Commit** with `auto(refine): description`

### Role: validate

1. **Run** project checks:
   - Test suite (pytest or project-specific)
   - `/integrity` tier checks (if available)
   - `/sync check` for state drift
2. **Classify** results: pass / warn / fail
3. **Report** results
4. If FAIL and --coordinate: post alert to coord.jsonl
5. Do NOT modify any files

### Role: expand

1. **Scan** for gaps: untested code, missing docs, incomplete knowledge
2. **Prioritize** by impact
3. **Select** top gap
4. **Fill** the gap (write tests, docs, or knowledge entries)
5. **Test** additions
6. **Commit** with `auto(expand): description`

### Role: review

1. **Read** recent sessions from `.self/channels/` (last 48h)
2. **Read** recent coord messages (if --coordinate)
3. **Synthesize**: what was accomplished, conflicts, patterns, risks
4. **Write** review summary to channel (via /save or direct file)
5. Do NOT modify code files

### Role: custom

1. **Interpret** the custom description as a work plan
2. **Execute** work matching the description
3. **Respect** all guardrails (Step 3)
4. **Commit** if changes were made

---

## Step 3: Guardrails Check

After EACH cycle, check ALL of these. If any STOP condition fires, go to Step 4 immediately.

### STOP conditions
- `cycle_count >= max_cycles` → stop (completed)
- `.self/auto/stop` file exists → stop (signalled)
- coord.jsonl has `{"type": "stop"}` targeting this agent → stop
- Error count > 3 in this cycle → stop (error cascade)
- `all_done` (no more unclaimed objectives) → stop (completed)

### NEVER conditions (hard guardrails — never violate these)
- NEVER modify `config/*.yaml` files
- NEVER modify `.claude/settings.json`
- NEVER amend commits or force push
- NEVER skip pre-commit hooks
- NEVER modify `.self/prm/objectives.md` (read-only in auto mode)

### If continuing

1. Increment `cycle_count`
2. If --coordinate: update heartbeat in manifest
3. Print brief status: `[auto] Cycle {n}/{max}: {role} — {summary}`
4. Go to Step 2

---

## Step 4: Shutdown

1. Print final summary:

```
## Auto Session Complete

**Role**: {role}
**Cycles**: {cycle_count}/{max_cycles}
**Stop reason**: {reason}

### Completed
- [x] Objective 1 (commit abc123)
- [x] Objective 2 (commit def456)

### Remaining
- [ ] Objective 3 (not started)
```

2. If --coordinate:
   - Release all claims in claims.jsonl
   - Post coord message: `{"type": "departed", ...}`
   - Deregister from manifest
   - If in worktree: ExitWorktree keep (preserves branch for PR)

3. Run `/save` with title: `auto-{role}: {summary}`

---

## Permission Matrix

| Action | achieve | refine | validate | expand | review |
|--------|---------|--------|----------|--------|--------|
| Read any file | yes | yes | yes | yes | yes |
| Edit src/ | yes | yes | no | yes | no |
| Edit tests/ | yes | yes | no | yes | no |
| Edit docs/ | no | yes | no | yes | no |
| Run tests | yes | yes | yes | yes | no |
| Git commit | yes | yes | no | yes | no |
| Create PR | yes | yes | no | yes | no |
| Post observations | yes | yes | yes | yes | yes |

---

## Use Cases

| When | Use |
|------|-----|
| Work through objectives solo | `/auto achieve` |
| Multiple agents on different roles | `/auto achieve --coordinate` in terminal 1, `/auto validate --coordinate` in terminal 2 |
| Quick quality pass | `/auto refine --max-cycles 2` |
| CI-like check | `/auto validate` |
| Fill gaps after a sprint | `/auto expand` |
| Understand what happened | `/auto review` |
| Check what's running | `/auto status` |
| Stop all agents | `/auto stop` |
