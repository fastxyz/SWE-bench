# FVK Specification for django__django-15037

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited unit is `django/core/management/commands/inspectdb.py`, specifically:

- `Command.handle_inspection()` relation-field generation.
- `Command.normalize_table_columns()`, added in V1 to reproduce generated field
  names for referenced table columns.

The observable under audit is the generated model field declaration for a
database foreign key. The relevant output property is whether a relation field
contains `to_field=<target model field name>` when the database constraint
references a non-primary-key target column.

## Intent Specification

For every single-column relation reported by backend introspection as:

```text
local_column -> (remote_column, remote_table)
```

`inspectdb` must generate a Django relation field whose semantic target matches
the database foreign key:

- If `remote_column` is the primary-key column of `remote_table`, the generated
  relation may omit `to_field` because Django defaults relations to the target
  primary key.
- If `remote_column` is not the primary-key column of `remote_table`, the
  generated relation must include `to_field` naming the target model field that
  `inspectdb` will generate for `remote_column`.
- The `to_field` value must be a Django model field name, not merely the raw
  database column name.
- Existing behavior unrelated to the target column must be preserved: relation
  type selection (`ForeignKey` vs. `OneToOneField`), self/forward model quoting,
  `models.DO_NOTHING`, `primary_key`, `unique` handling, null/blank handling,
  and `db_column` normalization.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt/issue | "Foreign key to a specific field is not handled in inspectdb" | Preserve the referenced target field, not only the referenced table. | Encoded in O1. |
| E2 | prompt/issue | `FOREIGN KEY(other_id) references foo(other_id)` and current output is "a FK to foo and not foo(other_id)" | For the concrete schema, generated `Bar.other` must target `Foo.other_id`, not `Foo.id`. | Encoded in O1 and F1. |
| E3 | prompt hint | "simple patch to handle FK to non pk field" | Generalize beyond the example to any non-primary-key target column. | Encoded in O1. |
| E4 | backend API | `BaseDatabaseIntrospection.get_relations()` returns `{field_name: (field_name_other_table, other_table)}`. | The remote column is already public introspection data and should be consumed by `inspectdb`. | Encoded in O1/O2. |
| E5 | Django docs | `ForeignKey.to_field`: by default Django uses the target primary key; a different referenced field must use `to_field`. | Emit `to_field` exactly when target column differs from target primary key. | Encoded in O1/O2. |
| E6 | Django model checks | `ForeignObject._check_to_fields_exist()` calls `_meta.get_field(to_field)`. | `to_field` must be the target model field name, not necessarily the raw DB column. | Encoded in O3. |
| E7 | inspectdb source | `normalize_col_name()` rewrites relation columns, reserved words, invalid identifiers, and conflicts. | Target field names used by `to_field` must follow the same normalization as generated target model fields. | Encoded in O3. |
| E8 | compatibility | No public backend API or management command signature change is required by the issue. | Keep changes internal to `inspectdb`; do not change backend `get_relations()` contracts or tests. | Encoded in O4/O5. |

## Formal Domain

The obligations range over relation columns for which:

- `column_name in relations`;
- `relations[column_name] == (rel_column, rel_table)`;
- the target table's primary-key column can be introspected as `target_pk`,
  possibly `None` for legacy tables without a detected primary key;
- the target table description can be normalized by `normalize_table_columns()`;
- the relation is represented through Django's existing single-column
  `get_relations()` contract.

Composite foreign-key behavior is outside this specific contract because
`get_relations()` does not expose a composite target tuple to `inspectdb`.

## Proof Obligations

- O1: Non-PK target preservation. If `rel_column != target_pk`, the generated
  relation declaration includes `to_field=target_field_name(rel_table,
  rel_column)`.
- O2: PK target frame. If `rel_column == target_pk`, the generated relation
  declaration omits `to_field` and keeps Django's default target-primary-key
  semantics.
- O3: Target field-name soundness. `target_field_name(rel_table, rel_column)` is
  the field name `inspectdb` would generate for `rel_column` in `rel_table`.
- O4: Relation-output frame. The V1 change does not alter relation type,
  referenced model spelling, `models.DO_NOTHING`, or unrelated field parameters.
- O5: Public compatibility. The fix does not change public APIs, backend
  introspection return shapes, or test files.

## Adequacy Audit

The specification is intent-derived rather than candidate-derived. The
pre-fix/current behavior described in the issue is treated as the bug: generating
a relation to `Foo` without `to_field` for `foo(other_id)` is SUSPECT legacy
behavior, not an invariant.

The formal obligations cover the full public issue family: foreign keys that
reference target columns other than the target primary key. They also cover the
primary-key frame condition so the fix does not over-emit `to_field` for normal
foreign keys or for primary keys whose database column is not named `id`.

## Compatibility Audit

Changed public symbols: none.

Changed internal symbols:

- Added `Command.normalize_table_columns(table_description, relations)`.
- Added local caches and helpers inside `Command.handle_inspection()`.

Public callers: `inspectdb` still exposes the same command arguments and output
stream behavior. Backend `get_relations()`, `get_constraints()`, and
`get_primary_key_column()` signatures are unchanged. Test files were not
modified.
