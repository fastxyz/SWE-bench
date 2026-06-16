## Root cause

`makemigrations --check` recorded the `check_changes` option but left
`self.dry_run` tied only to the explicit `--dry-run` flag. When model changes
were detected, the command followed the normal write path through
`write_migration_files()` or `write_to_last_migration_files()` and only called
`sys.exit(1)` afterward. This made `--check` report missing migrations, but only
after creating or updating migration files.

## Files changed

`repo/django/core/management/commands/makemigrations.py`

The command now treats `--check` as implying dry-run mode when initializing
`self.dry_run`. This reuses the existing no-write behavior in the migration file
writers, preserves the current migration summary output, and keeps the existing
non-zero exit status when changes are detected. The `--check` help text was
updated to document that it does not write migration files.

## Assumptions and alternatives considered

I assumed the issue is about all file-writing paths reachable from
`makemigrations --check`, not only the default migration creation path. Reusing
`self.dry_run` covers normal writes and `--update` writes/deletes without adding
separate checks around each write operation.

I considered moving `sys.exit(1)` before `write_migration_files()` when
`check_changes` is true. I rejected that because it would suppress the existing
summary of migrations that would be made, while the issue allows check commands
to log information before exiting.

I also considered changing only `write_migration_files()` to skip writes when
`check_changes` is true. I rejected that because `--check` should share the same
behavior as `--dry-run` earlier in the command flow, including avoiding
interactive prompts for defaults that are only needed when writing migrations.
