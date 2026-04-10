#!/bin/bash
# Session-start hook — lightweight agent registration
# Must complete fast (<3s) or Claude Code may time out silently

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$ROOT" ]]; then
    echo "Not in git repo"
    exit 0
fi

cd "$ROOT" || exit 0

# Use venv python directly (fast) — fall back to uv run (slow but works first time)
if [[ -x "$ROOT/.venv/bin/python" ]]; then
    PY="$ROOT/.venv/bin/python"
elif command -v uv &>/dev/null; then
    PY="uv run python"
else
    echo "No Python venv found, skipping session init"
    exit 0
fi

# Quick check: is self-cli importable?
if ! $PY -c "import core.reflexivity" 2>/dev/null; then
    echo "self framework not installed, skipping session init"
    exit 0
fi

# Create a fresh identity for this conversation.
# Always creates new — agent runtime state is gitignored so there's
# no stale identity to collide with.
OUTPUT=$($PY -c "
import sys
try:
    from core.reflexivity.identity import create_new_session_identity
    identity = create_new_session_identity()
    print(f'Agent: {identity.get(\"alias\", \"unknown\")} ({identity.get(\"id\", \"unknown\")})')
    print(f'Channel: {identity.get(\"channel\", \"main\")}')
except Exception as e:
    print(f'Agent init failed: {e}', file=sys.stderr)
" 2>&1) || OUTPUT=""

if [[ -n "$OUTPUT" ]]; then
    echo "$OUTPUT"
fi

# Reset session trace file
mkdir -p "$ROOT/.self/cache"
: > "$ROOT/.self/cache/session_traces.jsonl"
