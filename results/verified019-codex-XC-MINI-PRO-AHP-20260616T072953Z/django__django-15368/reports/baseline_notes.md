# Baseline Notes

## Root Cause

`QuerySet.bulk_update()` builds each field update as a `Case` expression with a
`When(..., then=attr)` branch per object. Before creating the `When`, it wrapped
any value that was not an `Expression` instance in `Value(attr, output_field=field)`.

Plain `F()` objects support expression resolution through `resolve_expression()`,
but they do not subclass `Expression`. As a result, assigning `F('name')` to a
model instance field and passing that instance to `bulk_update()` treated the
`F()` object as a literal value. The generated SQL therefore contained the string
representation, such as `'F(name)'`, instead of resolving it to the referenced
column.

## Files Changed

`repo/django/db/models/query.py`

- Changed the `bulk_update()` value check from `isinstance(attr, Expression)` to
  `hasattr(attr, 'resolve_expression')`.
- Removed the now-unused `Expression` import.

This matches the expression protocol already used elsewhere in Django's ORM
update and value preparation paths, while preserving the existing behavior for
plain Python values by continuing to wrap them in `Value()`.

## Assumptions and Alternatives

- I assumed the intended fix is to accept any expression-like object that
  implements `resolve_expression()`, not only `F()`. This follows the public hint
  and nearby ORM patterns.
- I considered explicitly checking `isinstance(attr, (Expression, F))`, but
  rejected it because it would fix only this one expression class and keep
  `bulk_update()` narrower than other update paths.
- I did not add or modify tests because the task explicitly forbids changing test
  files and running tests or code in this workspace.
