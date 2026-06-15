# Public Compatibility Audit

## Changed source surface

- `BaseDatabaseSchemaEditor.alter_index_together()` changed only the
  `constraint_kwargs` dictionary passed to `_delete_composed_index()`.

## Signatures and dispatch

- `alter_index_together(self, model, old_index_together, new_index_together)`:
  unchanged.
- `_delete_composed_index(self, model, fields, constraint_kwargs, sql)`:
  unchanged.
- `_constraint_names(self, model, column_names=None, unique=None,
  primary_key=None, index=None, foreign_key=None, check=None, type_=None,
  exclude=None)`: unchanged.
- `django/db/backends/mysql/schema.py` overrides `_delete_composed_index()` with
  `*args` and forwards to `super()`, so the changed dictionary content is
  accepted without dispatch changes.

## Serialization and migration operation shape

- `AlterIndexTogether` deconstruction and state behavior are unchanged.
- No migration operation class signature, serialized field, or public return
  shape changed.

Result: no compatibility finding for V1.
