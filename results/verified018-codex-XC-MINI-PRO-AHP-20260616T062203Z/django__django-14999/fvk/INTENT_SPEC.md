# Intent Spec

Status: constructed for FVK audit; no commands or tests were run.

## Public Intent Obligations

I1. A `RenameModel` database operation whose old and new model states resolve to the same database table must be a database no-op. This is derived from `benchmark/PROBLEM.md`: "RenameModel with db_table should be a noop" and "A RenameModel operation that already has db_table defined must be a noop."

I2. "No-op" is interpreted as no schema-editor side effects from `database_forwards()`: no table rename, no incoming relation `alter_field()`, and no auto-created M2M table or field alteration. This is derived from the issue's concrete symptoms: PostgreSQL drops and recreates foreign key constraints and SQLite recreates a table.

I3. `state_forwards()` must still rename the model state. The issue targets database side effects, not migration-state behavior, and `RenameModel`'s public purpose remains to rename the model.

I4. If the old and new database table names differ, existing `RenameModel` database behavior remains in scope: move the main table, repoint incoming relations, and handle applicable auto-created M2M schema changes. Public in-repo migration tests describe this branch as "RenameModel also repoints all incoming FKs and M2Ms."

I5. Table-name equality uses the same equivalence as the schema editor's existing table-rename no-op: exact equality, or lower-case equality on backends that ignore table-name case.

I6. The patch must not change the public method signature or migration operation API.

## Domain

The formal domain is one execution of `RenameModel.database_forwards(app_label, schema_editor, from_state, to_state)` after the migration states have been constructed. The proof abstracts Django model objects into:

- `AllowMigrate`: whether `allow_migrate_model()` permits database changes for the new model.
- `SameTable`: whether the old and new model states identify the same database table under I5.
- `RelatedCount`: number of related-object `alter_field()` calls the pre-existing non-no-op branch would perform.
- `M2MCount`: number of applicable auto-created local M2M entries the pre-existing non-no-op branch would process.

`RelatedCount` and `M2MCount` are non-negative integers. The audit proves partial correctness of side effects; termination is structurally evident for finite Django relation lists but is not machine-proved here.
