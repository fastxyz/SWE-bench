# Baseline Notes

## Root cause

`BaseDatabaseSchemaEditor.alter_index_together()` deleted removed
`index_together` entries by looking up constraints with only `index=True`.
Some backend introspection implementations report unique constraints as indexes
as well as unique constraints. When a model has both `unique_together` and
`index_together` on the same fields, the lookup can therefore return both the
unique constraint and the non-unique index, causing `_delete_composed_index()` to
raise `ValueError` because it expects a single matching database object.

## Changed files

- `repo/django/db/backends/base/schema.py`: narrowed the deletion lookup for
  removed `index_together` entries to `index=True, unique=False`, so only the
  non-unique index created for `index_together` is eligible for deletion. This
  leaves `alter_unique_together()` unchanged; it already asks for
  `unique=True`.

## Assumptions and alternatives

- Assumed an `index_together` entry always corresponds to a non-unique index.
  That matches the creation path, which calls `_create_index_sql()` with the
  `_idx` suffix rather than `_create_unique_sql()`.
- Considered changing backend introspection so unique constraints would not be
  reported as indexes. Rejected because the current introspection shape appears
  intentional for backends where unique constraints are physically backed by
  indexes, and other schema-editing code may rely on that information.
- Considered changing migration operation ordering or optimizer behavior based
  on the public hint. Rejected for this failure because the crash occurs even
  for the direct single operation that removes `index_together`; the ambiguity is
  in the database-object lookup performed during deletion.
- No tests or code were run, per task instructions.
