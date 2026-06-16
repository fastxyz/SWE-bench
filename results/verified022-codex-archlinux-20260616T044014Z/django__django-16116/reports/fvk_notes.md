## FVK decision notes

V1 stands unchanged. The audit's central finding is F-1: before V1,
`makemigrations --check` could reach the migration writers before exiting with
status `1`. PO-1 through PO-4 show that the V1 assignment
`self.dry_run = options["dry_run"] or options["check_changes"]` is sufficient
because it happens before normal, update, empty, and merge writer dispatch, and
each writer's file effects are guarded by `not self.dry_run`.

No additional source edit was made for `run_formatters(self.written_files)`.
F-2 records that in dry-run/check mode the formatter helper may still be called
with an empty file list, but PO-2 and PO-4 show that no migration files are
written, deleted, or formatted as written migrations. The public issue requires
"without making migrations"; it does not require changing existing explicit
`--dry-run` formatter behavior.

No tests were edited. F-3 identifies the useful regression test: assert that
`makemigrations --check` leaves the migration directory unchanged when changes
are detected. The task forbids modifying test files, so this remains iteration
guidance only.

The proof artifacts are constructed, not machine-checked, per F-4 and PO-8.
They justify keeping V1 as the final source state for this task, with the
machine-check commands recorded in `fvk/PROOF.md` for later use outside this
environment.
