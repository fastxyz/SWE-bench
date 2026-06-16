# Baseline Notes

## Root cause

When an `OR` condition combines a related `__in` lookup with an aggregate
lookup, Django moves the whole `OR` branch into `HAVING`. The compiler then
adds expressions referenced by `HAVING` to `GROUP BY`.

The related `__in` lookup correctly narrows a queryset RHS to the target
column when rendering the `IN (subquery)` predicate, but the `GROUP BY`
collection path asks the raw nested `sql.Query` for its group-by columns before
that lookup rendering happens. Because `sql.Query` inherited the default
expression behavior, it reported itself as a group-by expression. Compiling that
raw subquery in `GROUP BY` used the queryset's default select list, producing a
multi-column subquery such as `SELECT U0.id, U0.created, ...`, which PostgreSQL
rejects as "subquery must return only one column".

## Changed files

`repo/django/db/models/sql/query.py`

Added `Query.get_group_by_cols()` so nested raw `Query` expressions contribute
only their external column dependencies to an outer query's `GROUP BY`, matching
the existing behavior of explicit `Subquery` expressions. Non-correlated RHS
querysets now contribute no extra group-by expression, while correlated
subqueries still expose required outer columns and preserve the multivalued
fallback.

## Assumptions and alternatives

I assumed the intended SQL shape is the one already produced for the actual
`IN` predicate: the RHS queryset should be treated as a subquery dependency, not
as a full expression that must itself be grouped by. This fits the reported
working variant using `values_list("id", flat=True)` and the existing
`Subquery.get_group_by_cols()` implementation.

I considered changing `RelatedIn.as_sql()` to narrow the RHS select list earlier,
but that would only address related `__in` and would leave the broader grouping
behavior of raw nested queries inconsistent with `Subquery`. I also considered
special-casing `Lookup.get_group_by_cols()` to ignore RHS querysets for `IN`,
but that would skip legitimate external-column dependencies for correlated
subqueries.
