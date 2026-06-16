## Root cause

`inspectdb` already receives the remote column for each foreign key from
`connection.introspection.get_relations()`, where each entry is shaped as
`local_column: (remote_column, remote_table)`. The command used only the remote
table when generating `ForeignKey` and `OneToOneField` declarations. As a result,
a database foreign key such as `bar.other_id REFERENCES foo(other_id)` was
generated as a relation to `Foo`'s default primary key instead of preserving the
explicit non-primary-key target column with `to_field`.

## Changed files

`repo/django/core/management/commands/inspectdb.py`

- Added small caches for generated field-name mappings and primary-key columns
  by table while `inspectdb` is running.
- Added `normalize_table_columns()` so the command can reproduce the model field
  name that will be generated for a referenced table column, including existing
  normalization behavior for relation columns, reserved words, and conflicts.
- Updated relation generation to compare the referenced column with the target
  table's primary-key column. When they differ, the generated relation now
  includes `to_field` using the target model field name.

`reports/baseline_notes.md`

- Added this implementation note as required by the benchmark task.

## Assumptions and alternatives considered

I assumed `to_field` should be emitted only when the foreign key references a
non-primary-key column. If a foreign key references a target table's primary key,
even when that primary key column is not named `id`, Django's default relation
target is already correct.

I considered using the remote database column name directly as `to_field`. That
would fix the simple `other_id` example, but it would be wrong when `inspectdb`
renames the target column to a valid or non-conflicting model field name, because
`to_field` expects the Django model field name rather than the raw database
column.

I considered changing backend introspection, but the existing backend contract
already exposes the remote column through `get_relations()`. The bug is in how
`inspectdb` consumes that information, so the fix stays in the management
command.
