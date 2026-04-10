#!/bin/bash
# Session-end hook - multi-agent cleanup
# Runs automatically at conversation end
#
# Actions:
# 1. Push sync state (local only by default)
# 2. Release file reservations
# 3. Update last_active timestamp
# 4. Warn if active task not completed
# 5. Cleanup stale worktrees (optional)

set -e

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$ROOT" ]]; then
    exit 0
fi

cd "$ROOT" || exit 0

# Use uv run to ensure virtualenv with self-cli is active
PY="uv run python"

# Check if framework is available
if ! $PY -c "import core.reflexivity" 2>/dev/null; then
    exit 0
fi

# 1. Push sync state (local only - no remote push without explicit flag)
SYNC_OUTPUT=$($PY -c "
from extensions.multi_agent.sync import update_sync_state
from extensions.multi_agent.channel import get_sync_channels
channels = get_sync_channels()
update_sync_state(channels, remote=False)
" 2>&1) || {
    echo "Warning: Sync push failed: $SYNC_OUTPUT" >&2
}

# 2. Release file reservations
RELEASE_OUTPUT=$($PY -c "
from extensions.multi_agent.reserve import release_reservation
release_reservation(all_reservations=True)
" 2>&1) || {
    echo "Warning: Reservation release failed: $RELEASE_OUTPUT" >&2
}

# 3. Update last_active timestamp
TOUCH_OUTPUT=$($PY -c "
from core.reflexivity.identity import touch_identity
touch_identity()
" 2>&1) || {
    echo "Warning: Identity touch failed: $TOUCH_OUTPUT" >&2
}

# 4. Warn if active task not completed
TASK_WARN=$($PY -c "
from core.reflexivity.identity import get_current_task
task = get_current_task()
if task and task.get('task_id'):
    from tooling.cli.tasks import list_tasks
    all_tasks = list_tasks(status='in-progress')
    for t in all_tasks.tasks:
        if t.id == task['task_id']:
            print(f'Active task not completed: {t.title} ({t.id}). Consider /handoff.')
            break
" 2>&1) || true
if [[ -n "$TASK_WARN" ]]; then
    echo ""
    echo "$TASK_WARN"
fi

# 5. Cleanup stale worktrees (only if worktrees exist)
if [[ -d "../.worktrees" ]]; then
    CLEANUP_OUTPUT=$($PY -c "
from extensions.multi_agent.worktree import cleanup_stale_worktrees
cleanup_stale_worktrees(max_age_days=1, dry_run=False, quiet=True)
" 2>&1) || {
        echo "Warning: Worktree cleanup failed: $CLEANUP_OUTPUT" >&2
    }
fi

echo "Session ended. State synced."
