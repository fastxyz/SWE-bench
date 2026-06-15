# Public Compatibility Audit

Status: constructed from source inspection, not machine-checked.

## Changed symbols

`_json_value_literal(value)`

- New private helper in `django/db/models/fields/json.py`.
- No public API exposure.
- No callsite compatibility issue.

`KeyTransformIn`

- New lookup class registered on `KeyTransform`.
- Public surface affected: ORM lookup syntax `JSONField key transform + __in`.
- Method signatures match inherited lookup hooks: `resolve_expression_parameter(self, compiler, connection, sql, param)` and `split_parameter_list_as_sql(self, compiler, connection)`.
- No public subclass override compatibility issue was found in allowed source: this is a new class, not a signature change to an existing public method.

`KeyTransformExact.process_rhs()`

- Existing method now calls `_json_value_literal(value)` instead of inline `json.dumps({'value': value})` for Oracle RHS literals.
- Public behavior is preserved for values without single quotes and improved for quote-containing strings.
- No signature or return-shape change.

`KeyTransform.register_lookup(KeyTransformIn)`

- Adds lookup dispatch for `__in` on key transforms.
- No existing lookup registration is removed.

## Public callsites and overrides

Allowed-source search showed JSON key-transform lookups are created through Django's lookup registry rather than direct public construction of a `KeyTransformIn` class. Existing direct uses of `KeyTransform`, `KeyTextTransform`, exact comparisons, and expression RHS values retain their APIs.

## Compatibility verdict

Pass. The patch adds a specialized lookup and a private helper without changing public signatures. The only behavior change is for the bug surface and quote-safe Oracle exact RHS literals.
