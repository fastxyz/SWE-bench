# Intent Spec

Status: constructed from public issue text and in-repository source, not from hidden tests or upstream fixes.

## Required Behavior

1. `QuerySet.bulk_update(objs, fields)` must accept model instances whose updated field value is a plain `F("...")` expression object.
2. For such an object, the generated update expression must treat the `F()` value as an expression and resolve it to the referenced same-row column.
3. The generated SQL must not contain the string representation of the `F()` object as a literal parameter for the updated field.
4. Existing plain Python field values remain literal assignments and continue to be wrapped in `Value(..., output_field=field)`.
5. Existing validation and frame behavior of `bulk_update()` remains unchanged: primary keys are required, field names must be concrete non-primary-key fields, related-field preparation still runs, batching and PK filtering are unchanged, and backend casting behavior is unchanged.
6. The public API shape is unchanged: no signature change, no new required argument, no changed return type.

## Domain

The in-domain values for this audit are field values read by `getattr(obj, field.attname)` during `bulk_update()`:

- Values with `resolve_expression`, including plain `F()` objects.
- Values without `resolve_expression`, including ordinary strings and other literal field values.

The audit preserves the existing downstream update restrictions. Expressions are resolved through Django's update path with `allow_joins=False` and `for_save=True`; expressions requiring joins remain governed by the existing update compiler behavior.
