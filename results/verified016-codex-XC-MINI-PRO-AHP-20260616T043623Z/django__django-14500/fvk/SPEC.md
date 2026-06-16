# FVK Spec for django__django-14500

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

This FVK pass audits the V1 change for the migration replacement recorder state:
`MigrationExecutor.check_replacements()` and its composition with
`unapply_migration()` for replacement migrations. The rest of Django's migration
executor is treated as context unless it contributes directly to the observable
reported by the issue: rows present or absent in `django_migrations`.

The formal core is in:

- `fvk/mini-migrations.k`
- `fvk/migration-executor-spec.k`

These files model the recorder as a set of migration keys. This matches
`MigrationRecorder.applied_migrations()`, which exposes rows as a dict keyed by
`(app, name)`, and `record_unapplied()`, which deletes rows by `(app, name)`.

## Intent Spec

I-001. When a squashed replacement migration is unapplied, the replacement
migration's own recorder row must be absent after the migrate run.

I-002. The unapply operation for a replacement migration must not remove only
the individual replaced migration rows; it must also reconcile the squashed
replacement row.

I-003. The existing forward reconciliation remains required: when all replaced
migration rows are recorded as applied, the replacement migration row must be
recorded as applied, including no-op migrate runs where the replaced rows were
already present.

I-004. A row in `django_migrations` is the observable applied/unapplied state:
row present means applied, row absent means unapplied.

I-005. The fix must preserve public API compatibility: no signature, return
type, or caller protocol change is needed for `MigrationExecutor` or
`MigrationRecorder`.

## Public Evidence Ledger

E-001, prompt: "Squashed migration is not marked as unapplied" gives I-001.

E-002, prompt: "When unapplying a squashed migration and the replaced migration
files are still around, the MigrationExecutor mark the squash migration as
unapplied, too, not only the replaced migrations." gives I-001 and I-002.

E-003, public hint: "The squashed migration is not marked as applied" is
evidence that replacement-row reconciliation must be symmetric with the existing
apply-side behavior, not only direct unapply-side behavior. This supports I-003
and the choice to audit `check_replacements()`.

E-004, source comment in `MigrationLoader.build_graph()`: "The replacing
migration is only marked as applied if all of its replacement targets are."
This supports the invariant that a replacement key is applied exactly when all
keys in its `replaces` list are applied.

E-005, source comment in `MigrationExecutor.check_replacements()`: "Mark
replacement migrations applied if their replaced set all are" and "Do this
unconditionally on every migrate" supports I-003 and the decision to keep this
method as the central reconciliation point.

E-006, source comment in `MigrationRecorder`: "If a migration is unapplied its
row is removed from the table. Having a row in the table always means a
migration is applied." This supports I-004 and the set abstraction.

E-007, public tests in `tests/migrations/test_executor.py` check that applying
all replaced migrations marks the replacement as applied, and that no-op migrate
still marks an already-satisfied replacement as applied. These are supporting
evidence for I-003, not the sole source of the issue intent.

## Abstract Model

Let `Key` be a migration key `(app_label, migration_name)`.

Let `A` be the recorder-applied set read at entry to `check_replacements()`.

Let `R(k)` be the finite, non-empty replacement target set from
`migration.replaces` for a replacement migration key `k`.

Let `KRep` be the set of replacement migration keys in
`self.loader.replacements`.

The intended post-state `A'` after `check_replacements()` is:

- For every `k` in `KRep`, `k in A'` iff every key in `R(k)` is in `A`.
- For every `x` not in `KRep`, `x in A'` iff `x in A`.

This is a snapshot reconciliation over the recorder state read at method entry,
which matches both the current implementation shape and loader's applied-status
calculation. The issue scope concerns direct replacement targets whose migration
files remain present.

## Formal Spec English

C-001. If all replaced keys for a replacement key `k` are in the entry applied
set and `k` is absent, `check_replacements()` records `k` as applied.

C-002. If all replaced keys for `k` are in the entry applied set and `k` is
already present, `check_replacements()` preserves `k`.

C-003. If at least one replaced key for `k` is missing from the entry applied
set and `k` is present, `check_replacements()` records `k` as unapplied.

C-004. If at least one replaced key for `k` is missing from the entry applied
set and `k` is already absent, `check_replacements()` preserves that absence.

C-005. `check_replacements()` does not alter non-replacement keys.

C-006. After `unapply_migration()` unapplies a replacement migration `k`, it
removes every key in `R(k)`. Since `R(k)` is non-empty, the following
`check_replacements()` call must leave `k` absent.

C-007. Applying or no-op migrating after all keys in `R(k)` are present must
leave `k` present.

C-008. The change does not alter public method signatures, return types, or
caller protocols.

## Adequacy Audit

C-001 passes: it restates I-003 and E-005.

C-002 passes: it is the stable already-applied case implied by I-003.

C-003 passes: it is the missing V1/public issue behavior from I-001 and I-002.

C-004 passes: it is the stable already-unapplied case implied by I-001 and the
row-presence convention in I-004.

C-005 passes: no public intent supports changing unrelated recorder rows.

C-006 passes: it composes the issue's unapply path with the source behavior of
`unapply_migration()` and `migrate()` calling `check_replacements()`.

C-007 passes: it preserves the public apply-side behavior from E-003, E-005,
and E-007.

C-008 passes: the V1 source diff changes only internal branch behavior and a
docstring in `check_replacements()`.

No formal-English claim is weaker than the public issue intent. No claim depends
solely on V1's current output.

## Public Compatibility Audit

Changed symbol: `MigrationExecutor.check_replacements()`.

Public compatibility status: pass. The V1 patch does not change the method
signature, return value, attributes, call order, or public data shape. It adds a
recorder delete in a state that public intent says must be unapplied.

Callers: `MigrationExecutor.migrate()` continues to call `check_replacements()`
unconditionally after all plan modes. No caller changes are required.

Subclass/override compatibility: no public virtual dispatch signature changed.

Producer/consumer compatibility: `MigrationRecorder.record_unapplied()` already
accepts `(app, name)` and deletes rows by that key; V1 uses this existing
producer/consumer protocol.
