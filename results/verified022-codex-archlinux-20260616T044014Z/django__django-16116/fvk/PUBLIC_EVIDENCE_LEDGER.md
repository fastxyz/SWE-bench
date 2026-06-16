# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt / issue | "`makemigrations --check` generating migrations is inconsistent with other uses of `--check`" | `--check` should not take the normal migration-writing path. | Encoded by claims C1-C5. |
| E2 | prompt / issue | "without actually intending to create the migrations" | The observable file-system effect of creating migration files is forbidden in check mode. | Encoded by no-write/no-delete postconditions. |
| E3 | prompt / issue | "necessary to use both `--check` and `--dry-run`" | `--check` alone should acquire the no-write behavior currently associated with `--dry-run`. | Encoded by C0 and PO-1. |
| E4 | prompt / issue | "`migrate --check` and `optimizemigration --check`, which just exit (after possibly logging a bit)" | Check mode may log, but should exit before applying/writing changes. | Encoded by output not being constrained and by no-write claims. |
| E5 | prompt / issue | "`makemigrations --check` should just exit without making migrations" | If missing migrations exist, exit non-zero without writing migration files. | Encoded by C1 and C2. |
| E6 | in-repo command help | `--dry-run`: "Just show what migrations would be made; don't actually write them." | Dry-run is the existing local no-write mechanism. | Used as implementation-compatible design evidence for setting `self.dry_run`. |
| E7 | in-repo public tests | `test_makemigrations_check` asserts `SystemExit` when changes exist and success when no changes exist. | Existing public tests cover exit status but not the no-write obligation. | Test gap recorded as F-3. |
| E8 | implementation | `write_migration_files()` writes only under `if not self.dry_run`. | Setting `self.dry_run` before writer dispatch prevents normal and update file writes/deletes. | Encoded by PO-2 and PO-3. |
| E9 | implementation | `handle_merge()` writes merge migration files only under `if not self.dry_run`. | Setting `self.dry_run` before conflict/merge dispatch prevents merge-file writes. | Encoded by PO-4. |
| E10 | implementation | `run_formatters(self.written_files)` is called after the normal writer even when `self.written_files` is empty. | This is a residual dry-run behavior, but not a migration-file creation/update/delete effect. | Recorded as F-2; no source change justified by this issue. |

