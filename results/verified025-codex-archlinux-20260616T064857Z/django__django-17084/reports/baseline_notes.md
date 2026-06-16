## Root cause

`Query.get_aggregation()` decides whether `aggregate()` can be compiled as a
single query or must wrap the current query in an inner subquery. Since Django
4.2, filtering against window annotations is handled through `qualify`, but
`aggregate()` did not account for aggregate expressions that reference selected
annotations containing window functions.

For a query shaped like:

```python
queryset.annotate(cumul_DJR=Window(...)).aggregate(
    cumul_DJR_total=Sum("cumul_DJR")
)
```

`Sum("cumul_DJR")` resolves to a `Ref` to the selected `cumul_DJR` annotation.
When `get_aggregation()` chose the direct aggregation path, it inlined that
reference back to the underlying `Window(...)` expression, producing SQL like
`SUM(... OVER (...))`. PostgreSQL rejects that shape because aggregate function
calls cannot contain window function calls.

## Files changed

`repo/django/db/models/sql/query.py`

Tracked whether any aggregate expression references an existing selected
annotation whose expression has `contains_over_clause`. If so, `get_aggregation()`
now uses the existing `AggregateQuery` subquery wrapping path. That path projects
the window annotation in the inner query and lets the outer aggregate reference
the projected alias, avoiding an aggregate call directly around a window
function.

## Assumptions and alternatives considered

I assumed the intended supported case is aggregating over a selected window
annotation, matching the issue example. I kept the fix limited to references to
existing annotations instead of trying to support arbitrary expressions such as
`aggregate(total=Sum(Window(...)))`, because the existing aggregate-subquery
rewrite projects annotations and columns but does not generally lift arbitrary
window-containing expression trees into the inner query.

I considered treating any aggregate with `contains_over_clause` as requiring a
subquery. That would correctly identify more invalid direct SQL shapes, but it
would not by itself rewrite direct window expressions into inner-query aliases
and could leave the outer query with the same forbidden aggregate-over-window
structure. The narrower annotation-reference check fixes the reported
regression by using machinery that already preserves `Ref` aliases correctly.

No tests or code were run, in accordance with the benchmark instruction for this
session.
