# Proof Obligations

Status: constructed, not machine-checked.

## PO-1 - Check implies dry-run before writer dispatch

Claim: when `options["check_changes"]` is true, `self.dry_run` is true before
any path can call `write_migration_files()`, `write_to_last_migration_files()`,
or `handle_merge()`.

Evidence: `handle()` initializes `self.dry_run` from `options["dry_run"] or
options["check_changes"]` before conflict/merge handling, questioner creation,
autodetection, empty handling, update handling, or normal writer dispatch.

FVK claim: C0.

Status: discharged by static inspection and symbolic model.

## PO-2 - Normal detected-changes path does not write under check

Claim: if model changes are detected, `--update` is false, and `--check` is
true, the command calls `write_migration_files()` with `self.dry_run = true`;
therefore the guarded file-writing block is skipped and exit status `1` is
raised after logging.

Evidence: normal path calls `write_migration_files(changes)`, then `sys.exit(1)`
when `check_changes` is true. `write_migration_files()` performs directory
creation, file open/write, `self.written_files.append()`, and update deletion
only under `if not self.dry_run`.

FVK claim: C1.

Status: discharged by static inspection and symbolic model.

## PO-3 - Update path does not write or delete under check

Claim: if `--update` validation reaches the writer and `--check` is true,
`write_to_last_migration_files()` may compute an updated migration object, but
the eventual call to `write_migration_files(..., update_previous_migration_paths)`
does not write the new file or delete the previous file because `self.dry_run`
is true.

Evidence: update deletion is inside the same `if not self.dry_run` block as the
file write.

FVK claim: C2.

Status: discharged for file-system effects. In-memory mutation inside
`write_to_last_migration_files()` is outside the "making migrations" file-system
obligation and does not persist to disk.

## PO-4 - Empty and merge writer paths do not write under check

Claim: if `--check` is combined with `--empty` or with `--merge` conflict
handling, writer paths still observe `self.dry_run = true` and do not create
migration files.

Evidence: `--empty` calls `write_migration_files()`, which is guarded by
`self.dry_run`; `handle_merge()` writes merge files only under `if not
self.dry_run`.

FVK claims: C4 and C5.

Status: discharged for no-write behavior. Exact statuses are not used as
public-intent proof.

## PO-5 - No-changes check succeeds without writes

Claim: if no model changes are detected and `--check` is true, the command logs
"No changes detected" when verbosity permits, does not call a writer, and does
not call `sys.exit(1)`.

Evidence: the `if not changes` branch contains only logging.

FVK claim: C3.

Status: discharged.

## PO-6 - Non-check behavior remains framed

Claim: if `--check` and explicit `--dry-run` are false, detected changes still
reach the existing file-writing path.

Evidence: `self.dry_run` remains false when both options are false.

FVK claim: C6.

Status: discharged by static inspection and symbolic model.

## PO-7 - Compatibility is preserved

Claim: the fix changes only option semantics and help text; it does not change
public Python signatures or internal helper call protocols.

Evidence: no function signatures changed and no callsite receives new
arguments.

FVK audit: `PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged.

## PO-8 - Machine-check caveat

Claim: the written `.k` proof obligations are constructed but not
machine-checked in this environment.

Evidence: the task forbids running K tooling.

Status: open until a human runs the emitted `kompile` and `kprove` commands.

