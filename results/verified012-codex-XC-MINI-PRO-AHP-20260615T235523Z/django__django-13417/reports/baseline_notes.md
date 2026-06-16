# Baseline Notes

## Root cause

`QuerySet.ordered` treated a model's `Meta.ordering` as sufficient proof that
the queryset would produce ordered SQL whenever `query.default_ordering` was
enabled. That did not match SQL generation for grouped aggregate queries:
`SQLCompiler.get_order_by()` can initially pick up `Meta.ordering`, but
`SQLCompiler.as_sql()` suppresses that meta ordering when a `GROUP BY` clause is
emitted. As a result, annotated aggregate querysets with default model ordering
could report `ordered == True` even though their SQL had no `ORDER BY`.

## Changed files

`repo/django/db/models/query.py`

Updated the `QuerySet.ordered` property so default model ordering only counts
when the query is not grouped. Explicit `order_by()` and `extra(order_by=...)`
continue to report ordered, matching the compiler behavior that keeps explicit
ordering for grouped queries.

## Assumptions and rejected alternatives

I assumed the public contract of `QuerySet.ordered` should reflect the actual
presence of an ordering in generated SQL, not merely whether default ordering is
configured on the model. This follows the issue description and the existing
compiler behavior for `GROUP BY` queries.

I considered changing annotation or grouping setup to clear
`query.default_ordering`, but rejected that because the mismatch is limited to
introspection: the compiler already emits the intended SQL. Mutating query state
earlier would be a broader behavioral change and could affect cloning or later
explicit ordering calls unnecessarily.

I also considered consulting the SQL compiler from `QuerySet.ordered`, but
rejected that because the property is a lightweight query-state check elsewhere
in the code. Checking `query.group_by` keeps the change local and mirrors the
specific compiler branch that suppresses default meta ordering.
