# Baseline Notes

## Root cause

`JSONField` key transforms use backend JSON extraction SQL on the left-hand side, but the inherited generic `__in` lookup prepared right-hand-side literals only as JSON-encoded parameters. On SQLite this leaves scalar comparisons such as `JSON_EXTRACT(...) IN ('14')`, where the extracted value is a typed SQL scalar. On MySQL it leaves `JSON_EXTRACT(...)` compared directly with plain parameters instead of JSON values. On Oracle, JSON string values are JSON-encoded with quotes on the RHS while `JSON_VALUE()` returns the unquoted scalar. The existing key-transform `__exact` lookup already performs backend-specific RHS wrapping, but `__in` did not.

## Files changed

`repo/django/db/models/fields/json.py`

Added `KeyTransformIn` and registered it on `KeyTransform`. The new lookup adapts each direct RHS element during iterable lookup preparation:

- MySQL wraps values with `JSON_EXTRACT(%s, '$')`.
- SQLite wraps non-JSON-null values with `JSON_EXTRACT(%s, '$')`.
- Oracle converts the prepared JSON literal into a `JSON_VALUE()` or `JSON_QUERY()` SQL expression, following the existing exact-lookup behavior.

This keeps the fix scoped to JSON key transforms and leaves normal field `__in` behavior unchanged.

`reports/baseline_notes.md`

Added this explanation of the root cause, changed files, assumptions, and rejected alternatives as required by the task.

## Assumptions and alternatives

I assumed `value__key__in=[x]` should compare values the same way as `value__key=x` for JSON scalar, object, and array values on all supported JSON backends. I also assumed expression RHS values should continue through the generic expression compilation path, so the new adaptation applies only to direct literal parameters.

I considered changing the generic `In` lookup or `JSONField` preparation, but rejected that because the failure is specific to JSON key transforms and backend JSON extraction semantics. I also considered duplicating `KeyTransformExact.process_rhs()` at the whole-RHS level, but adapting each iterable parameter via `resolve_expression_parameter()` is more targeted and preserves existing `IN` list handling such as parameter splitting.
