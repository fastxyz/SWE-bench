# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public behavior

`makemigrations --check` now behaves as check-only for migration-file writes.
This is the intended public behavior change from E1-E5.

## Signatures and dispatch

- `Command.add_arguments()` signature is unchanged.
- `Command.handle()` signature is unchanged.
- `write_migration_files()` and `write_to_last_migration_files()` signatures are
  unchanged.
- No virtual method call was given new required arguments.
- No return type or producer/consumer data shape was changed.

## Option compatibility

- Explicit `--dry-run` remains supported and continues to set dry-run behavior.
- Ordinary `makemigrations` without `--check` remains on the write path.
- The `--check` help text now documents the intended no-write behavior.

## Result

No unhandled public callsite, subclass override, or API signature compatibility
issue was found by static inspection.

