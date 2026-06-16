# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - ForeignKey db parameters carry target collation

Statement: For any `ForeignKey` field `F` with target field `T`, `F.db_parameters(connection)` returns:

- `"type"` equal to `F.db_type(connection)`;
- `"check"` equal to `F.db_check(connection)`;
- `"collation"` equal to `T.db_parameters(connection).get("collation")`.

Evidence: E2, E3.

Discharge: Source inspection of `repo/django/db/models/fields/related.py::ForeignKey.db_parameters()`. K claim 1 in `fvk/django-15629-spec.k`.

Status: discharged by V1.

## PO2 - FK create/add column SQL emits target collation

Statement: If an FK field's `db_parameters()` returns a truthy `"collation"` value `C`, then `BaseDatabaseSchemaEditor.column_sql()` and `add_field()` include that collation in the emitted column definition through `_iter_column_sql()`.

Evidence: E1, E2, E5.

Discharge: Existing `column_sql()` passes `field.db_parameters()` into `_iter_column_sql()`, and `_iter_column_sql()` yields `_collate_sql(C)` when `field_db_params.get("collation")` is truthy. PO1 supplies the FK collation input. K claim 2 models this composition.

Status: discharged by V1 plus existing schema-editor code.

## PO3 - Referenced PK/unique collation changes trigger related FK handling

Statement: For retained primary key or unique target fields, incoming FK constraints must be dropped and related FK columns must be updated when either `(old_type != new_type)` or `(old_collation != new_collation)`.

Evidence: E2, E3, E4.

Discharge: Source inspection of `repo/django/db/backends/base/schema.py::_alter_field()`, where `old_collation` and `new_collation` are read from `old_db_params` and `new_db_params`, and `drop_foreign_keys` now includes type or collation change. K claim 3 models the collation-only trigger.

Status: discharged by V1.

## PO4 - Related FK column alteration includes new collation and preserves nullability handling

Statement: Each related FK column selected for update receives a backend type-alter call whose new type includes the new related field collation when present, and the existing backend helper remains responsible for nullability.

Evidence: E1, E2, E5.

Discharge: Source inspection of the `rels_to_update` loop in `_alter_field()`: V1 reads `new_rel.field.db_parameters()`, appends `_collate_sql(rel_collation)` to `rel_type` when present, then calls `_alter_column_type_sql(new_rel.related_model, old_rel.field, new_rel.field, rel_type)`. On MySQL, the existing override appends `NULL` or `NOT NULL` from `old_rel.field`, preserving the behavior shown in the issue. K claim 4 models nullable related alters.

Status: discharged by V1.

## PO5 - Frame conditions remain intact

Statement: The fix does not change tests, public method signatures, FK type selection, FK check constraints, constraint naming, or unrelated schema-editor branches.

Evidence: E5 plus source callsite audit.

Discharge: Diff inspection shows only two production source files changed. `ForeignKey.db_type()` still delegates to `target_field.rel_db_type()`. `ForeignKey.db_check()` remains the source of the FK `"check"` value. `_alter_field()` reuses the existing FK drop/alter/recreate sequence and backend type-alter hooks. Search did not find exact-dictionary `db_parameters()` consumers that would reject an added optional key.

Status: discharged by source audit.

## PO6 - Honesty and execution boundary

Statement: The FVK proof is constructed but not machine-checked, and no tests or project code are run.

Evidence: User task forbids tests, Python, and K tooling execution.

Discharge: Artifacts include exact commands to run later, but they were not executed.

Status: satisfied.
