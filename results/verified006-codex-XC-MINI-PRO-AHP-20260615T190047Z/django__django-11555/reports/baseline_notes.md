# Baseline Notes

## Root cause

`SQLCompiler.find_ordering_name()` expands default ordering for related models
when an `order_by()` target is a relation. That recursive path assumed every
item in the related model's `Meta.ordering` was a string and passed it to
`get_order_dir()`, which indexes the first character of the value. Expression
ordering entries such as `OrderBy(F(...))` or `Lower(...)` are not strings, so
they crashed before query compilation could turn them into `OrderBy`
expressions.

The top-level `get_order_by()` path already accepted expressions in ordering,
but the related-model expansion path did not. This is why the issue appears
when ordering by a parent/related model whose default ordering contains
expressions.

## Files changed

`repo/django/db/models/sql/compiler.py`

- Imported `F` so ordering expression trees can identify field-reference
  leaves.
- Added expression handling to `find_ordering_name()` before the string-only
  `get_order_dir()` call.
- Added `_resolve_ordering_expression()` to resolve plain `F()` leaves against
  the `opts` and table alias currently being processed by
  `find_ordering_name()`. This preserves the existing behavior that related
  model default ordering is resolved from the related model, not from the root
  query model.
- Reused the existing constant casting, `OrderBy` wrapping, and reverse-order
  handling so relation ordering such as `order_by('-relation')` still reverses
  related model default ordering consistently.

## Assumptions and alternatives considered

- I assumed `Meta.ordering` expression entries should behave like top-level
  expression ordering, but with `F()` references interpreted relative to the
  related model alias being expanded.
- I rejected simply skipping `get_order_dir()` for expressions and appending
  them unchanged because expressions such as `Lower('name')` would then resolve
  `name` from the root query model instead of the related model.
- I rejected changing `get_order_dir()` to tolerate non-string values because
  that would only avoid the immediate subscript crash and would leave expression
  resolution in the wrong compiler branch.
- I did not modify tests, and I did not run tests or repro code because the
  task explicitly forbids executing code in this session.
