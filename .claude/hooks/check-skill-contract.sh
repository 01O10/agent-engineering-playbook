#!/bin/bash
# Contract enforcement hook for Skill tool
# Runs precondition checks before skill execution
# Exit 0 = allow, Exit 2 = block

INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // ""')

# No skill specified, allow
[[ -z "$SKILL" ]] && exit 0

# Get repo root
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$ROOT" ]]; then
    exit 0  # Not in git repo, allow
fi

cd "$ROOT" || exit 0

# Check if contracts CLI exists
if ! command -v slf &>/dev/null; then
    exit 0  # CLI not available, allow
fi

# Run contract precondition check
# verify returns exit 0 on pass, exit 1 on fail
if slf contracts verify "$SKILL" --json 2>/dev/null; then
    exit 0  # Preconditions met
fi

# Check exit code - if contract not found, that's OK
if [[ $? -eq 1 ]]; then
    # Preconditions failed - show human-readable output and block
    echo "## Skill Contract Violation: $SKILL"
    echo ""
    slf contracts verify "$SKILL" 2>&1 | head -20
    echo ""
    echo "BLOCKED: Skill preconditions not met"
    echo "Fix the issues above before invoking this skill."
    exit 2
fi

# Any other exit code (no contract, etc.), allow
exit 0
