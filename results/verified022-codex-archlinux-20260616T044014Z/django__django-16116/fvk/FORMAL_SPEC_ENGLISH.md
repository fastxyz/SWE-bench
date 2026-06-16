# Formal Spec in English

Status: constructed, not machine-checked.

This file paraphrases the claims in `fvk/makemigrations-check-spec.k`.

## C0 - check initializes dry-run

For any explicit `--dry-run` value, if `--check` is true then command
initialization sets the abstract `dryRun` cell to true before dispatching to
any write-capable path.

## C1 - normal check path with changes

If `--check` is true, `--update` is false, `--empty` is false, merge handling is
not selected, conflicts are absent, and model changes are detected, then the
command reaches exit status `1` and performs zero migration-file writes and
zero migration-file deletes.

## C2 - update check path with changes

If `--check` is true, `--update` is true, update-specific validation has reached
the writer, merge handling is not selected, conflicts are absent, and model
changes are detected, then the command reaches exit status `1` and performs
zero migration-file writes and zero migration-file deletes.

## C3 - check path with no changes

If `--check` is true and no model changes are detected on the normal path, then
the command completes successfully and performs zero migration-file writes and
zero migration-file deletes.

## C4 - check plus empty migration path

If `--check` is true and the already-validated `--empty` path reaches
`write_migration_files()`, then the abstract write and delete counters remain
zero. The claim records the current return behavior, but the audit does not use
that status as public-intent evidence.

## C5 - check plus merge writer path

If `--check` is true and merge handling reaches the merge writer path, then the
abstract write and delete counters remain zero. The claim records the current
return behavior, but the audit does not use that status as public-intent
evidence.

## C6 - non-check behavior frame

If `--check` and explicit `--dry-run` are both false and changes are detected
on the normal path, the abstract command still performs a write and exits
successfully. This shows the fix does not turn ordinary `makemigrations` into
dry-run.

