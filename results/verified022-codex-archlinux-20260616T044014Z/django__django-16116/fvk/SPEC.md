# FVK Spec

Status: constructed, not machine-checked.

## Target

The audited unit is the `makemigrations` management command path that decides
whether detected migration changes are written to disk. The concrete source is
`repo/django/core/management/commands/makemigrations.py`.

The formal model abstracts Django's app registry, database consistency checks,
migration graph, and autodetector into command-state booleans:

- `CHECK`: the `--check` option is present.
- `DRYOPT`: the explicit `--dry-run` option is present.
- `EMPTY`: the `--empty` path is selected after validation.
- `UPDATE`: the `--update` path is selected and its pre-write validation has
  succeeded.
- `MERGE` and `CONFLICTS`: merge handling is selected and reaches the merge
  writer path.
- `CHANGES`: autodetection found model changes requiring migrations.

This abstraction preserves the property under verification: whether a reachable
path can create, update, delete, or format written migration files.

## Required behavior

For all in-domain command states:

S1. `CHECK = true` implies the command's internal `dryRun` state is true before
any migration writer is called.

S2. On the normal detected-changes path, `CHECK = true` and `CHANGES = true`
produce exit status `1` and leave the abstract write and delete counters at
zero.

S3. On the `--update` detected-changes path, assuming update-specific validation
has reached the writer, `CHECK = true` and `CHANGES = true` produce exit status
`1` and leave the abstract write and delete counters at zero.

S4. On the no-changes path, `CHECK = true` leaves write and delete counters at
zero and completes successfully.

S5. On `--empty` and merge-writer paths, `CHECK = true` leaves write and delete
counters at zero. Their exact exit status is not public-intent-derived and is
not used to justify the fix.

S6. `CHECK = false` and `DRYOPT = false` remain on the existing write path when
changes are detected. This frame condition guards against accidentally turning
ordinary `makemigrations` into dry-run.

S7. Exact logging and prompt text are not part of this spec. Logging is allowed
because the issue allows check commands to log before exiting.

## Public intent ledger

The complete ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries are:

- E3: `--check` alone should acquire the no-write behavior currently requiring
  `--dry-run`.
- E5: detected missing migrations must cause a non-zero exit without making
  migrations.
- E6: `self.dry_run` is the local no-write mechanism already used by
  `makemigrations`.
- E8 and E9: all relevant file writes are guarded by `not self.dry_run`.

## K artifacts

- `fvk/mini-python.k` models the command-state fragment and write effects.
- `fvk/makemigrations-check-spec.k` states claims C0-C6 against that model.

The K artifacts are an abstract semantics for the audited slice, not a full
Python or full Django semantics. They are adequate for this issue because the
property is a control/effect invariant over the `self.dry_run` flag and the
writer guards.

