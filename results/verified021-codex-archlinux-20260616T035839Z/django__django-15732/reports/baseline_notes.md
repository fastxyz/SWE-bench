# Baseline Notes

## Root cause

`BaseDatabaseSchemaEditor.alter_unique_together()` removes deleted
`unique_together` entries through `_delete_composed_index()`. That helper looked
up constraints only by the target columns and flags such as `unique=True`.

For a single-field `unique_together`, those criteria are not specific enough.
The same column can also have a field-level unique constraint or a primary key
constraint. PostgreSQL reports primary keys as unique constraints, so a model
with `unique_together = (("id",),)` can produce two matches for `id`: the
primary key and the generated `unique_together` constraint. The helper then
raises `ValueError` because it expects exactly one matching constraint.

## Changed files

`repo/django/db/backends/base/schema.py`

- `alter_unique_together()` now passes `primary_key=False` when deleting a
  generated unique-together constraint, so primary keys on the same column are
  not considered candidates.
- `alter_unique_together()` also passes the generated unique constraint suffix
  `_uniq` to `_delete_composed_index()`.
- `_delete_composed_index()` accepts an optional generated-name suffix. When the
  normal column/flag lookup finds multiple candidates, it computes Django's
  deterministic generated name for the unique-together constraint and prefers
  that match. The generated name is normalized with the backend's
  `identifier_converter()` before comparison so case-insensitive backends use
  the same form as introspection results.

## Assumptions

- Single-field `unique_together` constraints created by Django use the normal
  `_create_index_name(..., suffix="_uniq")` naming scheme, which is the same path
  used when adding `unique_together` constraints in the schema editor.
- The issue should be fixed at deletion time without changing the public model
  API or migration operation semantics.
- Explicit `Meta.constraints` and `Meta.indexes` should continue to be protected
  by the existing exclusion logic.

## Alternatives considered and rejected

- Skipping all deletion when the field remains `unique=True` or is a primary key:
  this would leave the redundant `unique_together` constraint in the database,
  so the migration would not actually apply the requested schema change.
- Selecting the first matching constraint returned by introspection: this would
  be backend/order dependent and could drop the field-level unique constraint or
  primary key instead of the generated `unique_together` constraint.
- Filtering only by `primary_key=False`: this fixes the primary key case but not
  the single-field `unique=True` case where two non-primary unique constraints
  can exist on the same column.
- Adding backend-specific PostgreSQL name handling: the generated constraint
  naming logic already lives in the base schema editor, and the ambiguity can be
  resolved using that existing deterministic naming helper.
