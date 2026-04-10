---
name: channel
description: Channel and session management (power features)
argument-hint: '[list | switch X | config | mute | archive | squash]'
---

# Channel Management

Manage session channels and advanced session operations.

## Multi-Agent Architecture

**Per-agent channel selection**: Each agent has its own `.current` in `.self/agents/{id}/`.
Switching channels only affects YOUR agent, not others.

**Channel inheritance**: Channels can inherit from others (see `/channel config`).
Default: new topic channels inherit from `main`.

## Arguments

$ARGUMENTS

### Argument Parsing

```
Parse $ARGUMENTS:

1. Subcommand (first word):
   - "list" → list channels
   - "switch" → switch to channel
   - "merge" → merge channel into current
   - "stash" → stash operations
   - "mute" → pause tracking
   - "unmute" → resume tracking
   - "archive" → archive sessions
   - "squash" → consolidate sessions
   - default → list (same as "list")
```

---

## Subcommand: `list` (default)

Show all channels:

```markdown
## Session Channels

  CHANNEL             SESSIONS   LAST ACTIVITY
  ─────────────────────────────────────────────
* main                     5     2026-01-28 21:30
  pipeline-refactor        2     2026-01-27 14:00
  infrastructure           1     2026-01-26 10:15
  ─────────────────────────────────────────────
  3 channels | 8 total sessions

Switch: `/channel switch <name>`
Create: `/channel switch <new-name>`
Delete: Archive all then remove
```

---

## Subcommand: `switch <name>`

Switch to channel (create if doesn't exist):

1. If channel exists: update `.self/agents/{id}/.current`
2. If doesn't exist: create `.self/channels/<name>/`, update `.current`, add to config.yaml

### Output

```markdown
**Switched to**: pipeline
**Sessions**: 2
**Last**: 2026-01-27 feature-work.md
```

---

## Subcommand: `merge <channel>`

Merge channel into current:

1. Move sessions from source to current channel
2. Update parent links chronologically

### Output

```markdown
## Merge Complete

**Merged**: pipeline → main
**Sessions moved**: 2
**Parent links updated**: 3
**Source**: pipeline (now empty)

Delete source with `/channel archive pipeline`
```

---

## Subcommand: `stash [list|pop|apply|drop|channel]`

Save/restore session context:

| Command | Effect |
|---------|--------|
| `stash` | Save current context |
| `stash list` | Show stashed sessions |
| `stash pop` | Apply + remove latest |
| `stash apply` | Apply, keep stash |
| `stash drop` | Discard latest |
| `stash channel X` | Create channel, apply stash |

### Stash Save

```markdown
## Session Stashed

**Saved to**: `.sessions/.stash/2026-01-28_22-30.md`
**From channel**: main
**Context**: 3 goals, 2 changes, 1 friction

Session cleared. Ready for fresh work.
Recover: `/channel stash pop`
```

### Stash List

```markdown
## Stash List

| # | Date | From | Preview |
|---|------|------|---------|
| 0 | 01-28 22:30 | main | "Adding auth..." |
| 1 | 01-28 20:15 | pipeline | "Refactoring..." |

Pop: `/channel stash pop`
Apply: `/channel stash apply`
```

---

## Subcommand: `mute`

Pause session tracking:

```markdown
## Session Muted

Conversation from now will NOT be captured in saves.

Resume:
- `/channel unmute` - discard muted portion
- `/channel unmute keep` - include muted portion
```

---

## Subcommand: `unmute [keep]`

Resume tracking:

```markdown
## Session Unmuted

**Muted duration**: 15 minutes
**Muted conversation**: [Discarded | Will include]

Tracking resumed.
```

---

## Subcommand: `archive [session|--before|--older]`

Archive sessions:

```
/channel archive <session>           # Archive one session
/channel archive --before 2026-01-20 # Archive before date
/channel archive --older 14          # Archive older than N days
/channel archive --closed            # Archive completed channels
```

### Output

```markdown
## Archive Complete

**Sessions archived**: 3 → `.sessions/_archive/`
**Parent links updated**: 1
```

---

## Subcommand: `squash`

Consolidate sessions:

1. Group sessions by theme
2. Merge into summary sessions
3. Archive originals

### Output

```markdown
## Squash Complete

**Sessions processed**: 5
**Squash sessions created**: 2

| Theme | Merged | New Session |
|-------|--------|-------------|
| auth | 3 | 2026-01-28_auth-summary.md |
| pipeline | 2 | 2026-01-28_pipeline-summary.md |

**Archived**: 5 sessions → `.sessions/_archive/`
```

---

## Directory Structure

```
.self/
├── agents/                     # Per-agent state
│   ├── main/                   # Main worktree agent
│   │   └── .current            # This agent's channel
│   └── agent-xxxx/             # Another agent
│       └── .current
└── channels/                   # Session storage (shared)
    ├── config.yaml             # Channel inheritance
    ├── .muted                  # Mute state (global)
    ├── main/                   # Default channel
    │   └── *.md
    ├── pipeline/               # Topic channel
    │   └── *.md
    └── _archive/               # Archived sessions
        └── main/
```

---

## Quiet Output

List:
```
* main (5) | pipeline (2) | infra (1)
```

Switch:
```
→ pipeline (2 sessions)
```

Merge:
```
merged: pipeline → main | 2 sessions
```

Stash:
```
stashed: 2026-01-28_22-30 | 3 goals
```

Mute:
```
muted | /channel unmute to resume
```

Archive:
```
archived: 3 sessions
```

---

## Constraints

- Channel operations update `.sessions/.current`
- Stash is LIFO (most recent first)
- Mute state is global (not per-channel)
- Archive moves to `_archive/`, doesn't delete
- Squash preserves key decisions and friction
