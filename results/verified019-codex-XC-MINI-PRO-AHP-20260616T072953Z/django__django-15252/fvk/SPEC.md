# FVK Spec for django__django-15252

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited production units are:

- `repo/django/db/migrations/recorder.py`
  - `MigrationRecorder.migration_table_allowed()`
  - `MigrationRecorder.ensure_schema()`
  - `MigrationRecorder.applied_migrations()`
  - `MigrationRecorder.record_applied()`
  - `MigrationRecorder.record_unapplied()`
  - `MigrationRecorder.flush()`
- `repo/django/db/migrations/executor.py`
  - the eager recorder-schema setup in `MigrationExecutor.migrate()`

The formal model abstracts a database connection into:

- `allowed`: the result of `router.allow_migrate_model(alias, Migration)`.
- `hasTable`: whether `django_migrations` exists before the call.
- effect counters: `creates`, `reads`, `writes`, and `deletes`.
- `planNonEmpty`: whether `MigrationExecutor.migrate()` has migrations to
  record.

The K artifacts are:

- `fvk/mini-django-migrations.k`
- `fvk/migration-recorder-spec.k`

## Public Evidence Ledger

`IE-1` Source: prompt/issue title.
Quoted evidence: "MigrationRecorder does not obey db_router allow_migrate
rules."
Semantic obligation: recorder behavior must consult the database router rather
than manage `django_migrations` unconditionally.
Status: encoded by `migration_table_allowed()` and claims over `allowed`.

`IE-2` Source: prompt/issue description.
Quoted evidence: "Django should only create tables in the first connection,
never in any of the other connections" and "my expectation would be that the
table is not created on any connection other than the 'default' connection."
Semantic obligation: on an alias where the router disallows the recorder model,
`ensure_schema()` must not create `django_migrations`.
Status: encoded by `PO-2`.

`IE-3` Source: prompt/issue description.
Quoted evidence: "record_applied does is a call to self.ensure_schema()" and
then "it tries to create the table."
Semantic obligation: `record_applied()` must not indirectly create or write
`django_migrations` when the router disallows the recorder model.
Status: encoded by `PO-5`.

`IE-4` Source: prompt/issue description.
Quoted evidence: "there will be similar issues with applied_migrations and
record_unapplied."
Semantic obligation: recorder reads and unapply writes must also respect the
router, and same-class write helpers should not bypass the policy.
Status: encoded by `PO-4`, `PO-5`, and `PO-6`.

`IE-5` Source: public hint/comment in the issue.
Quoted evidence: "it shouldn't try to create the migration table on a database
if it doesn't need to record any migrations there."
Semantic obligation: an empty migration plan must not force eager creation of
`django_migrations`.
Status: encoded by `PO-7`.

`IE-6` Source: public hint/comment in the issue.
Quoted evidence: "I think the suggested fix of refusing to migrate databases
where allow_migrate on the migration model returns False will still work."
Semantic obligation: the router question for the internal recorder table is the
router decision for the recorder's `Migration` model.
Status: encoded by `migration_table_allowed()` using `router.allow_migrate_model`.

`IE-7` Source: current source API in `repo/django/db/utils.py`.
Quoted evidence: `allow_migrate_model()` calls `allow_migrate(db,
model._meta.app_label, model_name=model._meta.model_name, model=model)`.
Semantic obligation: the fix should reuse Django's established router API and
argument shape.
Status: encoded by `PO-1`.

`IE-8` Source: public discussion in the issue.
Quoted evidence: "allow_migrate() operates at the model level and the migrate
command operates at the app level."
Semantic obligation: do not add an app-level "record only if app allowed" rule
without a reliable operation-level signal, because that can break mixed-model
migrations.
Status: recorded as `F-3` and `PO-9`.

## Intent-Only Specification

`IS-1` Router-disallowed recorder model:
If `router.allow_migrate_model(connection.alias, MigrationRecorder.Migration)`
returns `False`, the recorder must not create, read, insert into, delete from,
or flush `django_migrations` through `ensure_schema()`, `applied_migrations()`,
`record_applied()`, `record_unapplied()`, or `flush()`.

`IS-2` Router-allowed recorder model:
If the same router check returns `True`, legacy recorder behavior is preserved:
`ensure_schema()` returns when the table exists, creates it when missing, and
raises `MigrationSchemaMissing` on database creation errors.

`IS-3` Empty migration plan:
`MigrationExecutor.migrate()` must not eagerly call `ensure_schema()` when its
plan is empty, because no migration record can be written by that migrate call.

`IS-4` Non-empty migration plan:
`MigrationExecutor.migrate()` should still ensure the recorder schema before
applying a non-empty plan, preserving the old early-failure behavior when the
recorder table is allowed and missing.

`IS-5` Compatibility:
The public signatures of existing methods must remain compatible. New behavior
should be reachable through existing router configuration rather than new
arguments or settings.

## Formal Spec English Round Trip

`C-1` `ensureSchema` with `allowed = false` leaves `hasTable` and `creates`
unchanged.
Adequacy: passes `IS-1` and `IE-2`.

`C-2` `ensureSchema` with `allowed = true` and `hasTable = false` changes
`hasTable` to `true` and increments `creates`.
Adequacy: passes `IS-2`.

`C-3` `appliedMigrations` with `allowed = false` leaves `reads` unchanged and
returns the empty result.
Adequacy: passes `IS-1` and `IE-4`.

`C-4` `recordApplied` with `allowed = false` leaves `hasTable`, `creates`, and
`writes` unchanged.
Adequacy: passes `IS-1` and `IE-3`.

`C-5` `recordUnapplied` with `allowed = false` leaves `hasTable`, `creates`, and
`deletes` unchanged.
Adequacy: passes `IS-1` and `IE-4`.

`C-6` `flushRecorder` with `allowed = false` leaves `deletes` unchanged.
Adequacy: passes the same recorder-write policy derived from `IS-1`.

`C-7` `executorMigrate` with `planNonEmpty = false` leaves `allowed`,
`hasTable`, and `creates` unchanged.
Adequacy: passes `IS-3` and `IE-5`.

`C-8` `executorMigrate` with `planNonEmpty = true` and `allowed = false` leaves
`hasTable` and `creates` unchanged.
Adequacy: passes `IS-1`, `IS-4`, and `IE-6`.

## Public Compatibility Audit

No existing public method signature was changed. `migration_table_allowed()` is
a new helper and has no callers outside the recorder in the candidate patch.

`ensure_schema()` still returns `None` in all public paths; callers already
ignored the return value. `applied_migrations()` still returns a mapping,
returning `{}` in the same shape as the pre-existing "table missing" branch.
`record_applied()`, `record_unapplied()`, and `flush()` still accept the same
arguments.

The executor change preserves `migrate()`'s signature and only changes when the
existing `ensure_schema()` side effect is attempted.
