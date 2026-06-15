# Baseline Notes

## Root cause

`MigrationAutodetector.generate_altered_fields()` generated `AlterField`
operations without passing any dependency metadata to `add_operation()`.
When an existing scalar field such as `UUIDField` was changed to a relational
field such as `ForeignKey`, the migration autodetector correctly produced an
`AlterField`, but the migration splitting logic had no `_auto_deps` entry for
the referenced model's app. As a result, the generated migration could omit the
dependency on the target app's latest migration and later fail to resolve the
related model.

The autodetector already had `_get_dependencies_for_foreign_key()` and used it
for new related fields. The altered-field path simply did not apply the same
dependency collection to the new field definition.

## Changed files

`repo/django/db/migrations/autodetector.py`

- Added dependency collection in `generate_altered_fields()` for altered fields
  whose new definition has a resolved `remote_field.model`.
- Passed those dependencies to `add_operation()` for the generated
  `operations.AlterField`.
- Reused `_get_dependencies_for_foreign_key()` so swappable models, target apps,
  and explicit through models follow the same dependency behavior as `AddField`
  and related fields on `CreateModel`.

`reports/baseline_notes.md`

- Documented the root cause, the source change, and the assumptions for this
  benchmark task.

## Assumptions and alternatives considered

- Assumed the correct behavior is to depend on the referenced app's current
  migration leaf, matching existing autodetector behavior for `AddField` rather
  than hard-coding a dependency on an initial migration.
- Considered limiting the dependency to the exact transition from a non-relation
  to a relation. I rejected that because the underlying requirement is attached
  to the new field's relational target: changing an existing relation to a
  different target can need the same dependency handling, and the existing
  helper already defines the proper scope.
- Considered custom dependency construction in `generate_altered_fields()`. I
  rejected that to avoid duplicating swappable-model and through-model handling
  already present in `_get_dependencies_for_foreign_key()`.
- I did not modify tests or run code/tests because the task explicitly forbids
  both in this benchmark environment.
