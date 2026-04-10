#!/bin/bash
# Git safety hook for Claude Code
# Blocks dangerous git operations unless explicitly requested
# Exit 2 = block the operation

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Check for git commit --amend
if [[ "$CMD" =~ git[[:space:]]+commit.*--amend ]]; then
  echo "BLOCKED: Never amend commits unless user explicitly requests '--amend'" >&2
  echo "Create a NEW commit instead to preserve history" >&2
  exit 2
fi

# Check for git push --force or -f
if [[ "$CMD" =~ git[[:space:]]+push.*(--force|-f[[:space:]]|-f$) ]]; then
  echo "BLOCKED: Never force push unless user explicitly requests '--force'" >&2
  echo "Force pushing can destroy remote history" >&2
  exit 2
fi

# Check for --no-verify on commit
if [[ "$CMD" =~ git[[:space:]]+commit.*--no-verify ]]; then
  echo "BLOCKED: Never skip pre-commit hooks unless user explicitly requests '--no-verify'" >&2
  echo "Fix the hook issues instead of bypassing them" >&2
  exit 2
fi

# Check for destructive reset
if [[ "$CMD" =~ git[[:space:]]+reset[[:space:]]+--hard ]]; then
  echo "WARNING: git reset --hard will discard uncommitted changes" >&2
  echo "Proceeding - ensure this was intentional" >&2
fi

# Check for force delete branch
if [[ "$CMD" =~ git[[:space:]]+branch[[:space:]]+-D ]]; then
  echo "WARNING: git branch -D force deletes even unmerged branches" >&2
  echo "Proceeding - ensure this was intentional" >&2
fi

exit 0
