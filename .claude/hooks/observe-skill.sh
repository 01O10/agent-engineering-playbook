#!/bin/bash
# PostToolUse hook for Skill — emit observations to the memory stream.
#
# This bridges the gap between Claude Code's Skill tool execution and
# the self framework's observation system. Without this, ObservationHook
# (which lives in the Python composition system) never fires because
# skills are executed via SKILL.md prompts, not Python operators.
#
# Emits:
# - progress: when meaningful skills complete (save, decide, prm, domain, validate)
# - error: when skills fail (detected via tool_result patterns)
# - friction: when execution patterns indicate struggle (traces file)
#
# Trace file: .self/cache/session_traces.jsonl (reset on session start)

set -e

INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty')

# No skill name — nothing to observe
[[ -z "$SKILL" ]] && exit 0

# Strip fully-qualified prefix (e.g. "ms-office-suite:pdf" → "pdf")
SKILL="${SKILL##*:}"

ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[[ -z "$ROOT" ]] && exit 0
cd "$ROOT" || exit 0

# Ensure slf is available
if ! command -v slf &>/dev/null; then
    exit 0
fi

# --- Determine channel ---
CHANNEL=$(slf channel current -q 2>/dev/null || echo "main")

# --- Append trace ---
TRACE_DIR="$ROOT/.self/cache"
TRACE_FILE="$TRACE_DIR/session_traces.jsonl"
mkdir -p "$TRACE_DIR"

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // ""' | head -c 120)

# Detect errors from tool result (heuristic: look for error/fail keywords)
RESULT_SNIPPET=$(echo "$INPUT" | jq -r '.tool_result // ""' | head -c 500)
IS_ERROR=false
if echo "$RESULT_SNIPPET" | grep -qiE '(error|failed|exception|traceback|BLOCKED)'; then
    IS_ERROR=true
fi

jq -cn \
    --arg skill "$SKILL" \
    --arg args "$ARGS" \
    --arg ts "$TS" \
    --argjson error "$IS_ERROR" \
    '{skill: $skill, args: $args, ts: $ts, error: $error}' \
    >> "$TRACE_FILE" 2>/dev/null || true

# --- Emit progress for meaningful skills ---
PROGRESS_SKILLS="save decide prm domain validate"
if echo "$PROGRESS_SKILLS" | grep -qw "$SKILL"; then
    if [[ "$IS_ERROR" == "false" ]]; then
        OBS="progress: $SKILL completed"
        [[ -n "$ARGS" ]] && OBS="$OBS -- $ARGS"
        slf memory observe "$OBS" \
            -t auto-detected -t progress -t "skill:$SKILL" \
            -c "$CHANNEL" 2>/dev/null || true
    fi
fi

# --- Emit error observations ---
if [[ "$IS_ERROR" == "true" ]]; then
    ERR_MSG=$(echo "$RESULT_SNIPPET" | grep -ioE '(error|failed|exception)[^"]{0,80}' | head -1)
    [[ -z "$ERR_MSG" ]] && ERR_MSG="unknown error"
    slf memory observe "error: $SKILL failed -- $ERR_MSG" \
        -t auto-detected -t error -t "skill:$SKILL" \
        -c "$CHANNEL" 2>/dev/null || true
fi

# --- Friction detection (runs every invocation, cheap) ---
# Only run if we have enough traces
TRACE_COUNT=$(wc -l < "$TRACE_FILE" 2>/dev/null || echo "0")
if [[ "$TRACE_COUNT" -ge 3 ]]; then
    # Search-thrashing: same skill 3+ times in last 10 traces
    THRASH=$(tail -10 "$TRACE_FILE" | jq -r '.skill' 2>/dev/null | sort | uniq -c | sort -rn | head -1)
    THRASH_COUNT=$(echo "$THRASH" | awk '{print $1}')
    THRASH_SKILL=$(echo "$THRASH" | awk '{print $2}')
    if [[ "$THRASH_COUNT" -ge 3 && -n "$THRASH_SKILL" ]]; then
        slf memory observe "search-thrashing: $THRASH_SKILL called ${THRASH_COUNT}x in recent window" \
            -t auto-detected -t friction \
            -c "$CHANNEL" 2>/dev/null || true
    fi

    # Backtracking: A -> B -> A in last 3 traces
    if [[ "$TRACE_COUNT" -ge 3 ]]; then
        LAST3=$(tail -3 "$TRACE_FILE" | jq -r '.skill' 2>/dev/null)
        S1=$(echo "$LAST3" | sed -n '1p')
        S2=$(echo "$LAST3" | sed -n '2p')
        S3=$(echo "$LAST3" | sed -n '3p')
        if [[ "$S1" == "$S3" && "$S1" != "$S2" && -n "$S1" ]]; then
            slf memory observe "backtracking: $S1 -> $S2 -> $S3 (returned to previous approach)" \
                -t auto-detected -t friction \
                -c "$CHANNEL" 2>/dev/null || true
        fi
    fi

    # Error-retry: previous trace was error, current is success for same skill
    if [[ "$TRACE_COUNT" -ge 2 && "$IS_ERROR" == "false" ]]; then
        PREV=$(tail -2 "$TRACE_FILE" | head -1)
        PREV_SKILL=$(echo "$PREV" | jq -r '.skill' 2>/dev/null)
        PREV_ERROR=$(echo "$PREV" | jq -r '.error' 2>/dev/null)
        if [[ "$PREV_SKILL" == "$SKILL" && "$PREV_ERROR" == "true" ]]; then
            slf memory observe "error-retry: $SKILL failed then succeeded (silent friction)" \
                -t auto-detected -t friction \
                -c "$CHANNEL" 2>/dev/null || true
        fi
    fi
fi

exit 0
