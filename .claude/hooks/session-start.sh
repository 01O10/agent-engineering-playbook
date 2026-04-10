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

# Create a fresh identity for this session.
# Uses SSE port as session fingerprint to avoid creating duplicates
# if the hook fires more than once in the same session.
SESSION_FP="${CLAUDE_CODE_SSE_PORT:-$$}"
MARKER="$ROOT/.self/cache/.session-fp"
if [[ -f "$MARKER" ]] && [[ "$(cat "$MARKER" 2>/dev/null)" == "$SESSION_FP" ]]; then
    # Same session — reuse existing identity
    OUTPUT=$($PY -c "
import sys
try:
    from core.reflexivity.identity import get_or_create_identity
    identity = get_or_create_identity()
    print(f'Agent: {identity.get(\"alias\", \"unknown\")} ({identity.get(\"id\", \"unknown\")})')
    print(f'Channel: {identity.get(\"channel\", \"main\")}')
except Exception as e:
    print(f'Agent init failed: {e}', file=sys.stderr)
" 2>&1) || OUTPUT=""
else
    # New session — create fresh identity
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
    mkdir -p "$ROOT/.self/cache"
    echo "$SESSION_FP" > "$MARKER"
fi

if [[ -n "$OUTPUT" ]]; then
    echo "$OUTPUT"
fi

# Reset session trace file
mkdir -p "$ROOT/.self/cache"
: > "$ROOT/.self/cache/session_traces.jsonl"
