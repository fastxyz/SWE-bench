# Iteration Guidance

Status: constructed, not machine-checked.

## Applied in V2

1. Fix Oracle large-list splitting for `KeyTransformIn`.

   Trace: F1, PO6, PO7.

   Change: added an Oracle-specific `split_parameter_list_as_sql()` branch that chunks by RHS SQL fragment count when RHS params are empty.

2. Make Oracle inline JSON literals quote-safe.

   Trace: F2, PO5.

   Change: added `_json_value_literal()` and used it from both `KeyTransformExact` and `KeyTransformIn`.

## Kept from V1

1. Keep the per-element override point `resolve_expression_parameter()`.

   Trace: PO2, PO3, PO4, PO7.

   Reason: it adapts literal values while preserving expression compilation and generic `In` list handling.

2. Keep generic `None` removal for `__in`.

   Trace: F3, PO7.

   Reason: no public evidence in the issue requires changing SQL `NULL` semantics for `IN`.

3. Keep PostgreSQL/native JSON behavior delegated to inherited logic.

   Trace: I3, PO7.

   Reason: public evidence says PostgreSQL works, and `has_native_json_field` is the existing backend feature that distinguishes this path.

## Follow-up recommendations

1. Add hidden/public tests in the normal Django suite for:
   - SQLite and MySQL `value__c__in=[14]`;
   - Oracle `value__foo__in=['bar']`;
   - Oracle string values containing a single quote;
   - Oracle key-transform `__in` lists larger than `max_in_list_size`.

2. Run the emitted K commands in an environment with K installed if a machine-checked FVK proof is required.

3. Run Django's JSONField test subset on SQLite, MySQL, and Oracle in a real test environment. This proof does not execute project code or database queries.
