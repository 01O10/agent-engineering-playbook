#!/bin/bash
# Session-start hook - multi-agent initialization
# Runs automatically at conversation start
#
# Actions:
# 1. Ensure agent identity (creates if needed)
# 2. Ensure worktree exists (ENFORCED - creates isolated branch)
# 3. Pull sync state from other agents
# 4. Check for file reservation conflicts
# 5. Output context for agent
# 6. Start background heartbeat

set -e

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$ROOT" ]]; then
    echo "Not in git repo"
    exit 0
fi

cd "$ROOT" || exit 0

# Use uv run to ensure virtualenv with self-cli is active
PY="uv run python"

# Check if framework is available
if ! $PY -c "import core.reflexivity" 2>/dev/null; then
    echo "self framework not installed, skipping session init"
    exit 0
fi

# 1. Ensure agent identity
IDENTITY_OUTPUT=$($PY -c "
from core.reflexivity.identity import get_or_create_identity
identity = get_or_create_identity()
print(f\"AGENT_ID={identity['id']}\")
print(f\"AGENT_ALIAS={identity['alias']}\")
print(f\"CHANNEL={identity.get('channel', 'main')}\")
print(f\"WORKTREE_PATH={identity.get('worktree_path', '')}\")
" 2>&1) || {
    echo "Warning: Agent identity creation failed: $IDENTITY_OUTPUT" >&2
}

if [[ -n "$IDENTITY_OUTPUT" ]]; then
    # Export for use in this session
    eval "$IDENTITY_OUTPUT"
    export AGENT_ID AGENT_ALIAS CHANNEL WORKTREE_PATH
fi

# Guard: ensure AGENT_ID is set even if identity creation failed
if [[ -z "$AGENT_ID" ]]; then
    echo "Warning: Agent identity creation failed, using fallback" >&2
    AGENT_ID="agent-anon-$(date +%m%d-%H%M)"
    AGENT_ALIAS="anonymous"
    CHANNEL="main"
    export AGENT_ID AGENT_ALIAS CHANNEL
fi

# 2. Worktree isolation (DISABLED — single-agent project, worktree wipes main checkout)
# To re-enable for multi-agent: uncomment the block below
# WORKTREE_OUTPUT=$($PY -c "
# from extensions.multi_agent.worktree import ensure_worktree
# from core.reflexivity.identity import load_identity, save_identity
# worktree_path = ensure_worktree(quiet=True)
# if worktree_path:
#     identity = load_identity()
#     if identity and identity.get('worktree_path') != str(worktree_path):
#         identity['worktree_path'] = str(worktree_path)
#         save_identity(identity)
#     print(str(worktree_path))
# " 2>&1) || WORKTREE_OUTPUT=""
# if [[ -n "$WORKTREE_OUTPUT" ]]; then WORKTREE_PATH="$WORKTREE_OUTPUT"; fi

# 3. Pull sync state (quiet)
SYNC_OUTPUT=$($PY -c "
from extensions.multi_agent.sync import sync_pull_local
result = sync_pull_local(quiet=True)
" 2>&1) || {
    echo "Warning: Sync pull failed: $SYNC_OUTPUT" >&2
}

# 4. Check for reservation conflicts
CONFLICTS=$($PY -c "
from extensions.multi_agent.reserve import check_reservation_conflicts
result = check_reservation_conflicts(quiet=True)
if result.get('has_conflicts'):
    for c in result.get('conflicts', []):
        agent = c.get('agent_alias') or c.get('agent_id')
        patterns = ', '.join(c.get('patterns', []))
        print(f'  Warning: {patterns} reserved by {agent}')
" 2>&1) || {
    echo "Warning: Reservation check failed: $CONFLICTS" >&2
    CONFLICTS=""
}

# 5. Output context
echo "───────────────────────────────────"
if [[ -n "$AGENT_ALIAS" ]]; then
    echo "Agent: $AGENT_ALIAS ($AGENT_ID)"
else
    echo "Agent: $AGENT_ID"
fi
if [[ -n "$WORKTREE_PATH" ]]; then
    echo "Worktree: $WORKTREE_PATH"
fi
echo "Channel: ${CHANNEL:-main}"
if [[ -n "$CONFLICTS" ]]; then
    echo ""
    echo "⚠ Reservation conflicts:"
    echo "$CONFLICTS"
fi
echo "───────────────────────────────────"

# 5.5 Hydrated context
CONTEXT=$($PY -c "
from extensions.memory.context import build_context, format_context_markdown
print(format_context_markdown(build_context()))
" 2>/dev/null) || CONTEXT=""
if [[ -n "$CONTEXT" ]]; then
    echo ""
    echo "$CONTEXT"
fi

# 6. Reset session trace file (for PostToolUse friction detection)
mkdir -p "$ROOT/.self/cache"
: > "$ROOT/.self/cache/session_traces.jsonl"

# 7. Sync state baseline
OUTPUT=$(slf state sync -q 2>&1 || true)
# Don't output state sync noise unless there's an error
if [[ "$OUTPUT" == *"Error"* ]]; then
    echo "$OUTPUT"
fi

# 8. Start background heartbeat (dies with shell)
(while true; do
    $PY -c "from core.reflexivity.identity import write_heartbeat; write_heartbeat()" 2>/dev/null
    sleep 300
done) >/dev/null 2>&1 &
# No need to track PID — background process dies when parent shell exits
