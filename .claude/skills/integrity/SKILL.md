# Tier Integrity Check

Check knowledge tier consistency — hashes, claims, cascades.

## Arguments

- (none) → run full check and show status
- `status` → show current state without running checks
- `cascade` → show pending cascades
- `changed PATH` → react to a file change

## Behavior

Run `uv run python scripts/tier_integrity.py` with the appropriate subcommand.

### Default (no args): Full Check

```bash
uv run python scripts/tier_integrity.py check
```

Show the result. If there are pending cascades, list them with their next action.

### `status`

```bash
uv run python scripts/tier_integrity.py -v status
```

### `cascade`

```bash
uv run python scripts/tier_integrity.py cascade
```

### `changed PATH`

```bash
uv run python scripts/tier_integrity.py changed PATH
```

Then show updated status.
