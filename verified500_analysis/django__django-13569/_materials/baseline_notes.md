# Baseline Notes

## Root cause

`SQLCompiler.get_group_by()` adds grouping expressions from non-reference
`ORDER BY` expressions whenever a query has aggregation. For `order_by('?')`,
`get_order_by()` represents the ordering as `OrderBy(Random())`. Since
`Random()` has no aggregate and uses the base expression grouping behavior, its
`get_group_by_cols()` result is the random function itself. The compiler then
adds `RANDOM()`/`RAND()` to `GROUP BY`, causing otherwise identical aggregate
rows to be split by a volatile value unrelated to the selected aggregate.

## Files changed

`repo/django/db/models/sql/compiler.py`

The order-by contribution to `GROUP BY` now appends only grouping expressions
that either contain column references or contain `RawSQL`. This keeps the
existing behavior for field-based ordering and opaque raw SQL ordering, while
excluding column-free expressions such as `Random()` from grouping.

## Assumptions

I assumed the bug is limited to order-by expressions being added to grouping,
not to selected expressions or HAVING expressions. Those paths remain unchanged
because selected non-aggregate expressions still need normal grouping behavior.

I assumed raw SQL orderings must continue to be grouped because Django cannot
introspect whether a `RawSQL` fragment references columns.

## Alternatives considered and rejected

Special-casing `Random` in `get_group_by()` would fix the reported query, but
it would leave the same problem for other column-free ordering expressions.

Changing `Expression.get_group_by_cols()` globally to return an empty list for
column-free expressions would have a wider behavioral impact, including SELECT
and HAVING grouping paths. The compiler-only change is narrower and targeted at
the source of this issue.
