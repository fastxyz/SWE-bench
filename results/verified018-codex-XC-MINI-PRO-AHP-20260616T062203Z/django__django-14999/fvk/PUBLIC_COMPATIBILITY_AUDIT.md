# Public Compatibility Audit

Status: source inspection only; no commands that execute Django were run.

## Changed Symbol

`django.db.migrations.operations.models.RenameModel.database_forwards(self, app_label, schema_editor, from_state, to_state)`

- Signature changed: no.
- Return value contract changed: no explicit return value before or after; V1 may return earlier on the same-table database no-op branch.
- Public call protocol changed: no. Migration execution still calls `operation.database_forwards(self.app_label, schema_editor, old_state, project_state)`.
- Subclass/override impact: no `RenameModel` subclass or override was found in inspected `repo/django` and public in-repo migration tests. Other migration operations define their own `database_forwards()` methods but are not dispatched through `RenameModel`.

## Call Sites

`repo/django/db/migrations/migration.py`, lines 122-125, calls `operation.database_forwards(...)` through the common operation API. V1 preserves the method signature and argument order.

Public tests also call operation instances directly, but the signature remains identical.

## Producer/Consumer Shape

V1 does not change migration serialization, `deconstruct()`, operation attributes, state mutation, or schema editor API. It only prevents schema-editor calls in the same-table branch.

Compatibility verdict: pass.
