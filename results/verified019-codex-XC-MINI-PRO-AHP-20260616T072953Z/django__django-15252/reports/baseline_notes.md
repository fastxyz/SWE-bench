# Baseline Notes

## Root cause

`MigrationRecorder` managed the `django_migrations` table directly and never
consulted database routers before checking, creating, reading, or writing that
table. `MigrationExecutor.migrate()` also called `recorder.ensure_schema()`
before it knew whether there were any migrations to record. As a result,
running migrations on a database alias that routers intentionally excluded
could still create `django_migrations` or attempt writes to it.

## Changed files

`repo/django/db/migrations/recorder.py`

- Imported the global database `router`.
- Added `migration_table_allowed()` so the recorder checks whether its internal
  `Migration` model may be migrated on the current connection alias.
- Made `ensure_schema()` return without creating `django_migrations` when the
  router disallows the recorder model.
- Made `applied_migrations()` return an empty mapping when the recorder model is
  disallowed, matching the existing "no table means no applied migrations"
  behavior without querying the disallowed database.
- Made `record_applied()`, `record_unapplied()`, and `flush()` no-op when the
  recorder model is disallowed.

`repo/django/db/migrations/executor.py`

- Delayed the eager `ensure_schema()` call until after the migration plan is
  known.
- Skipped eager recorder table creation entirely for an empty migration plan,
  because there are no migration records to write in that case.

## Assumptions and alternatives considered

I assumed the router decision for the internal `django_migrations` table should
use the same `router.allow_migrate_model()` path as normal migration
operations. This keeps the fix aligned with Django's existing router API and
lets database-wide routers, such as "only migrate on default", block recorder
table creation on excluded aliases.

I considered making the executor decide whether each user migration should be
recorded based on the migration's app label or individual operations. I rejected
that as too broad for this issue because Django migrations can contain mixed
model-specific and non-model operations, and the current operation API doesn't
provide a reliable generic "this operation actually ran" result. The targeted
fix is to make the recorder itself obey routers and avoid creating its table
when no records are needed.

I also assumed that an empty migration plan shouldn't force creation of
`django_migrations`. Existing applied migrations already imply the table exists,
and if there is no plan, the executor has no new migration rows to record.
