# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`django.db.migrations.serializer.TypeSerializer.serialize()`

Compatibility result: pass.

Reason:

- Method name and signature are unchanged.
- Return shape remains `(string, set(imports))`.
- The serialized string for `models.Model` remains `models.Model`.
- The only changed value is the import set paired with that string.

## Public Callers

Observed public/internal callers in the audited path:

- `serializer_factory(value).serialize()`
- `MigrationWriter.serialize(value)`
- `OperationWriter.serialize()`
- `MigrationWriter.as_string()`

Compatibility result: pass.

Reason: all callers already consume the import set returned by serializers. The
change supplies a missing import token and does not require caller changes.

## Subclasses and Overrides

No public subclass or override of `TypeSerializer.serialize()` is changed by
this patch. The serializer registry remains unchanged.

Compatibility result: pass.

## Test Files

No test files are modified.

Compatibility result: pass.
