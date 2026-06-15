# Baseline Notes

## Root cause

Combined querysets store their component `Query` objects in `Query.combined_queries`.
`Query.clone()` copied that tuple shallowly, so a queryset derived from a combined
queryset shared the same component `Query` instances as the original queryset.

For `union()` queries, later derived operations such as `order_by().values_list()`
can require the SQL compiler to narrow or otherwise prepare the component select
lists for the derived query. Because the component queries were shared, that
state could leak back into the original ordered union. The original query could
then still order by the position of a column that was no longer present in the
shared component select list, producing SQL like `ORDER BY (4)` against a
one-column select.

## Files changed

`repo/django/db/models/sql/query.py`

`Query.clone()` now recursively clones `combined_queries`. This restores the
normal queryset cloning invariant for set-operation queries: operations on a
derived combined queryset get independent child `Query` objects and cannot
mutate the original combined queryset's children.

## Assumptions and alternatives

I assumed the failure was caused by query-state aliasing between the original
combined queryset and a derived queryset, matching the public hint about a query
attribute being changed without copying first.

I considered changing `SQLCompiler.get_combinator_sql()` around the
`set_values()` propagation path. That method already clones a component query
before applying `set_values()` in the obvious path, so tightening cloning at the
general `Query.clone()` boundary is a smaller and more robust fix for all
derived combined querysets.

I also considered cloning the operands at `QuerySet._combinator_query()` time.
That would protect the newly created union from its source querysets, but the
reported breakage involves queryset derivation after the union has already been
created. Cloning inside `Query.clone()` directly addresses that derivation path
without changing set-operation construction semantics.
