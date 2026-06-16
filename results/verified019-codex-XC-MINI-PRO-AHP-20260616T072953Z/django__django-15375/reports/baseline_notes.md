# Baseline Notes

## Root cause

`Aggregate.resolve_expression()` supports the `default` argument by wrapping the resolved aggregate in a `Coalesce`. The resolved aggregate itself has `is_summary` set from the `summarize` argument passed by `Query.add_annotation()`, but the newly-created `Coalesce` wrapper kept the class default `is_summary = False`.

For `aggregate()` queries over a queryset that already has annotations, `Query.get_aggregation()` uses `is_summary` to move terminal aggregate expressions from the inner subquery to the outer aggregate query. Because the defaulted aggregate was hidden inside a non-summary `Coalesce`, Django left it in the inner query and produced an outer query with an empty select list, matching the reported invalid SQL shape.

## Changed files

`repo/django/db/models/aggregates.py`

The default-handling branch now stores the generated `Coalesce` in a local variable, copies the resolved aggregate's `is_summary` flag onto that wrapper, and returns the wrapper. This makes defaulted terminal aggregates behave like non-defaulted terminal aggregates during subquery aggregation planning.

## Assumptions and alternatives

I assumed the `Coalesce` wrapper should preserve the summary state of the aggregate it wraps. In the failing `aggregate()` path this state is `True`, which lets `get_aggregation()` move the expression to the outer query.

The public hint showed setting `coalesce.is_summary = True` directly. I considered that literal change, but rejected it because `Aggregate.resolve_expression()` is also used for normal aggregate annotations where `summarize` is `False`. Copying `c.is_summary` fixes the reported terminal aggregation case while preserving the existing expression-resolution contract for non-terminal annotations.

I did not modify tests because the benchmark instructions require the project's fixed and hidden test suite to remain unchanged.
