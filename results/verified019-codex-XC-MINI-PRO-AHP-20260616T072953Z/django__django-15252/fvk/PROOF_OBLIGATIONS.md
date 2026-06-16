# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Router Decision Uses the Established Django API

Claim:
`MigrationRecorder.migration_table_allowed()` returns exactly
`router.allow_migrate_model(self.connection.alias, self.Migration)`.

Evidence:
`IE-6`, `IE-7`.

Discharge condition:
The helper must pass the current connection alias and the recorder's internal
`Migration` model to Django's router API.

Status:
Discharged by `repo/django/db/migrations/recorder.py`.

## PO-2: `ensure_schema()` Is a No-Op When the Recorder Model Is Disallowed

Claim:
If `migration_table_allowed()` is false, `ensure_schema()` must return before
checking table existence or opening a schema editor.

Evidence:
`IE-1`, `IE-2`, `F-1`.

Formal claim:
`C-1` in `fvk/migration-recorder-spec.k`.

Status:
Discharged. The first branch in `ensure_schema()` returns when
`migration_table_allowed()` is false.

## PO-3: `ensure_schema()` Preserves Legacy Allowed-Database Behavior

Claim:
If `migration_table_allowed()` is true, `ensure_schema()` must keep the old
semantics: return when the table exists; otherwise create the recorder model;
wrap database creation errors in `MigrationSchemaMissing`.

Evidence:
`IS-2`, compatibility audit.

Formal claim:
`C-2` in `fvk/migration-recorder-spec.k` covers the creation path.

Status:
Discharged. The old `has_table()` and `schema_editor().create_model()` logic is
unchanged after the new router guard.

## PO-4: `applied_migrations()` Does Not Query a Disallowed Recorder Table

Claim:
If `migration_table_allowed()` is false, `applied_migrations()` returns `{}` and
does not call `has_table()` or query `migration_qs`.

Evidence:
`IE-4`, `F-1`.

Formal claim:
`C-3` in `fvk/migration-recorder-spec.k`.

Status:
Discharged. The current boolean short-circuit checks
`self.migration_table_allowed() and self.has_table()`.

## PO-5: `record_applied()` and `record_unapplied()` Do Not Write on Disallowed Aliases

Claim:
If `migration_table_allowed()` is false, `record_applied()` and
`record_unapplied()` return without calling `ensure_schema()`, `create()`, or
`delete()`.

Evidence:
`IE-3`, `IE-4`, `F-1`.

Formal claims:
`C-4` and `C-5` in `fvk/migration-recorder-spec.k`.

Status:
Discharged. Both methods begin with the same router guard and return when it is
false.

## PO-6: `flush()` Follows the Same Recorder Write Policy

Claim:
`flush()` must not delete migration records on an alias where the recorder model
is disallowed. If allowed, it should only delete when the table exists.

Evidence:
`IE-4` by same-class write consistency; compatibility audit.

Formal claim:
`C-6` in `fvk/migration-recorder-spec.k`.

Status:
Discharged. The current code requires both `migration_table_allowed()` and
`has_table()` before deleting.

## PO-7: Empty Migration Plans Do Not Eagerly Create `django_migrations`

Claim:
`MigrationExecutor.migrate()` must not call `self.recorder.ensure_schema()` when
the migration plan is empty.

Evidence:
`IE-5`, `F-2`.

Formal claim:
`C-7` in `fvk/migration-recorder-spec.k`.

Status:
Discharged. `migrate()` computes or receives `plan`, then calls
`ensure_schema()` only under `if plan:`.

## PO-8: Public API Compatibility Is Preserved

Claim:
No existing public method signature or return shape used by callers changes.

Evidence:
`F-5`; static callsite scan.

Discharge condition:
Existing callers can keep invoking the same methods with the same arguments.

Status:
Discharged. The patch adds a helper and changes side effects under router/empty
plan conditions but does not change public signatures.

## PO-9: Broader Per-Operation Recording Is Not a Safe Minimal Obligation

Claim:
The V2 patch must not add an app-label-only guard to migration recording unless
the design can distinguish full, partial, and zero operation execution within a
single migration.

Evidence:
`IE-8`, `F-3`.

Discharge condition:
Reject app-label-only recording changes for this repair; document the design
gap for future iteration.

Status:
Discharged by leaving V1 source unchanged and documenting the unresolved design
question in `F-3` and `fvk/ITERATION_GUIDANCE.md`.
