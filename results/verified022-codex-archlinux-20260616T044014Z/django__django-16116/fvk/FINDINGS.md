# Findings

Status: constructed, not machine-checked.

## F-1 - Resolved code bug: `--check` used to write before exiting

Input: `makemigrations --check` with detected model changes requiring a
migration.

Observed in V1 baseline analysis of the pre-fix command: the command called
`write_migration_files()` or `write_to_last_migration_files()` and only then
called `sys.exit(1)`.

Expected from E1-E5: the command may log what would be made, must exit
non-zero, and must not make migration files.

Resolution: V1 sets `self.dry_run = options["dry_run"] or
options["check_changes"]` before autodetection and writer dispatch. This
discharges PO-1 through PO-4.

## F-2 - Non-blocking residual: formatter helper is still called with no files

Input: any path using `write_migration_files()` with `self.dry_run = true`,
including explicit `--dry-run` and V1 `--check`.

Observed by static inspection: `write_migration_files()` calls
`run_formatters(self.written_files)` after the loop. In dry-run/check mode,
`self.written_files` remains empty, so no migration file is passed to the
formatter. If a formatter executable exists, `run_formatters([])` may still
spawn it with no file arguments.

Expected from this issue: no migration files are created, updated, deleted, or
formatted as written migrations. The issue does not state a no-subprocess
obligation, and changing this would also alter long-standing explicit
`--dry-run` behavior.

Decision: no V2 source change. Record as a possible cleanup outside the public
intent of django__django-16116, not as a correctness blocker for V1.

## F-3 - Test gap: public tests cover exit status but not no-write behavior

Input: `makemigrations --check` with detected model changes.

Observed by static inspection of public tests: `test_makemigrations_check`
checks that `SystemExit` is raised when changes exist and that no exception is
raised when no changes exist. It does not assert that no migration file was
written.

Expected from E2 and E5: no migration file write should occur.

Recommendation: if test edits were allowed, add a public regression assertion
that `--check` leaves the migration directory unchanged when changes are
detected. This task forbids modifying tests, so no test files were changed.

## F-4 - Proof honesty: constructed but not machine-checked

The K model, claims, and proof were written but not run through `kompile` or
`kprove`, as required by the task constraints. The no-write conclusion is based
on static source inspection and constructed symbolic proof, not a machine
checked `#Top` result.

