# Baseline Notes

## Root cause

`ForeignKey.db_parameters()` only exposed the related column type and check constraint. For text-like target fields, the target field's `db_collation` is stored in the target field's `db_parameters()` as `collation`, but that value was not propagated to the FK field. As a result, column creation and alteration SQL for FK columns could omit `COLLATE`, leaving MySQL with mismatched collations between the referenced primary key or unique column and the referencing FK column.

The alter path had a second gap: `BaseDatabaseSchemaEditor._alter_field()` only treated referenced primary key or unique field type changes as reasons to drop incoming FK constraints and update related FK columns. A collation-only change on the referenced field did not trigger the same related-column update path.

## Changed files

`repo/django/db/models/fields/related.py`

`ForeignKey.db_parameters()` now reads the target field's `db_parameters()` and includes its `collation` value while keeping the existing `rel_db_type()` behavior for the FK column type. This lets table creation and `add_field()` include the target collation in FK column definitions.

`repo/django/db/backends/base/schema.py`

`BaseDatabaseSchemaEditor._alter_field()` now considers collation changes, as well as type changes, when deciding whether incoming FK constraints must be dropped for a primary key or unique target field. When updating related FK columns, it appends the new collation to the related column type before using the existing type-alter helper, preserving backend-specific handling such as MySQL nullability in `MODIFY` statements.

## Assumptions and alternatives

I assumed the FK column should mirror only the target field's database collation metadata, not its check constraint or other field-specific parameters. Keeping `ForeignKey.db_check()` unchanged avoids copying target field validation constraints onto FK columns.

I considered adding a `ForeignKey.db_collation` property only. That would help some column creation paths, but it would not make schema alteration compare the target collation through `db_parameters()`, so collation-only target changes could still be missed.

I also considered changing backend-specific MySQL collation SQL. I rejected that as broader than necessary because the related-column update path can reuse the existing type-alter hook after adding the collation to the type string, which keeps the fix targeted to FK propagation.

No tests or project code were run, per the task constraints.
