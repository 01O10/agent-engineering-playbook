<!-- AUTO-GENERATED from .self/ - do not edit directly -->

# Git Commit Rules

## CRITICAL: Safety Rules

- **NEVER amend commits** unless user explicitly requests `--amend`
- **NEVER force push** (`--force`, `-f`) unless explicitly requested
- **NEVER skip hooks** (`--no-verify`) unless explicitly requested
- After pre-commit hook failure: fix issue, re-stage, create NEW commit

## Conventional Commits

Format: `type(scope): description`

| Type | Use for |
|------|---------|
| `feat:` | New features |
| `fix:` | Bug fixes |
| `chore:` | Maintenance, deps |
| `docs:` | Documentation |
| `refactor:` | Code restructure |
| `test:` | Test changes |
| `ci:` | CI/CD changes |

- Scope optional: `feat(pipeline):`, `fix(auth):`
- Breaking changes: `feat!:` or `BREAKING CHANGE:` in body
- Atomic commits: one logical change per commit

## Staging

- Add specific files by name (avoid `git add -A` or `git add .`)
- Never commit secrets (.env, credentials.json, etc.)
