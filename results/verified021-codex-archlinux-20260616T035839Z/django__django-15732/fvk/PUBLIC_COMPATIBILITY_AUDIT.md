# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

`BaseDatabaseSchemaEditor.alter_unique_together()`

- Public-ish backend schema-editor method used by migration operations.
- Signature unchanged.
- Behavior changed only for deleting old `unique_together` entries: primary keys
  are excluded, and generated `_uniq` names disambiguate duplicate unique
  candidates.

`BaseDatabaseSchemaEditor._delete_composed_index()`

- Private helper, but backend subclasses may override it.
- V1 changed the helper signature by adding an optional suffix argument.
- FVK Finding F-001 identified that the extra argument was unnecessary.
- V2 restores the original signature:
  `_delete_composed_index(self, model, fields, constraint_kwargs, sql)`.

## In-Repo Overrides And Calls

- `django/db/backends/mysql/schema.py` overrides
  `_delete_composed_index(self, model, fields, *args)` and remains compatible.
- Base calls from `alter_unique_together()` and `alter_index_together()` still
  pass the original four helper arguments.
- `alter_index_together()` behavior is unchanged by V2.

## Compatibility Verdict

No remaining in-repo signature or virtual-dispatch incompatibility was found by
source inspection. Third-party exact-signature overrides are less exposed under
V2 than under V1 because the helper argument list is unchanged from baseline.
