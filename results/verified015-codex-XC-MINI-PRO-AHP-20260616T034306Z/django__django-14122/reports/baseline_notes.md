## Root cause

`SQLCompiler.get_order_by()` still selected `Model._meta.ordering` for queries
with `query.group_by` set. `SQLCompiler.as_sql()` later suppressed the final
`ORDER BY` when that ordering came from model metadata, but the compiler had
already passed those ordering expressions into `get_group_by()`. Since
`get_group_by()` adds non-reference ordering expressions to the grouping list,
metadata ordering columns could change aggregate grouping even though default
ordering should not affect grouped queries.

## Changed files

`repo/django/db/models/sql/compiler.py`

Stopped applying model metadata ordering in `get_order_by()` when
`query.group_by` is not `None`. This keeps default `Meta.ordering` out of both
the generated `ORDER BY` and the intermediate ordering list used to populate
`GROUP BY`, while preserving explicit `order_by()`, `extra(order_by=...)`, and
queries that are not grouped.

## Assumptions and alternatives

I assumed `query.group_by is None` is the authoritative "no GROUP BY" sentinel,
matching `get_group_by()` itself. A truthiness check would miss an explicit
empty tuple/list group-by value, which still follows the grouped-query compiler
path.

I considered filtering metadata ordering only at the `get_group_by()` call site,
but rejected it because default ordering can also cause hidden select columns
through `get_extra_select()`. Skipping metadata ordering earlier is narrower and
keeps all downstream SQL-construction steps consistent.

I also considered changing `QuerySet.ordered`, but it already treats default
ordering as irrelevant for ordinary grouped queries; the bug is in SQL
compilation, where metadata ordering was still materialized before being
suppressed.
