# Baseline Notes

## Root cause

Replacement (squashed) migrations record the individual migrations they replace
when they are applied or unapplied. After a migrate run,
`MigrationExecutor.check_replacements()` reconciles the replacement migration's
own row in `django_migrations` by adding it when all replaced migrations are
recorded as applied.

The reconciliation was one-way. When a squashed migration was unapplied while the
replaced migration files were still present, `unapply_migration()` removed the
rows for the replaced migrations, but `check_replacements()` left the squashed
migration's own row in place. That made the recorder continue to report the
squashed migration as applied even though its replacement set was no longer fully
applied.

## Changed files

`repo/django/db/migrations/executor.py`

Updated `MigrationExecutor.check_replacements()` so replacement migration state
is reconciled in both directions. It still records the replacement migration when
all replaced migrations are applied, and it now removes the replacement
migration's own recorder row when any replaced migration is not applied.

## Assumptions

The intended source of truth for a replacement migration's applied state is the
applied state of all migrations listed in its `replaces` attribute. This matches
the existing loader behavior, which treats a replacement migration as applied
only when all replaced migrations are applied, and the existing executor behavior
that records replaced migration rows when applying a squashed migration.

No tests were run because the task instructions explicitly forbid running tests
or code in this benchmark session.

## Alternatives considered

One alternative was to update `unapply_migration()` to remove the squashed
migration row directly when unapplying a replacement migration. I rejected that
because `check_replacements()` is already the centralized reconciliation point
for replacement migration recorder state, and fixing it also handles no-op
migrate runs or unusual recorder states where the replacement row remains but
the replaced set is no longer fully applied.

Another alternative was to change `record_migration()` to record both the
replacement migration and each replaced migration directly. I rejected that as
broader than necessary and more likely to disturb the existing replacement
semantics, where the squashed migration's own row is maintained by
`check_replacements()`.
