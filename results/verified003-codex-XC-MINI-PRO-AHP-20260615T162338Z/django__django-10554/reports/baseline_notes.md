# Baseline Notes

## Root cause

`Query.clone()` made only a shallow copy of `combined_queries`. For a queryset built with
`union()`, `intersection()`, or `difference()`, that meant derived querysets continued to
share the same inner `Query` objects as the original combined queryset.

When a derived combined queryset narrowed its selected columns, for example through
`order_by().values_list('pk', flat=True)`, compiler setup could apply that projection to
the shared inner queries. The original queryset could then be evaluated with its original
outer ordering still referring to a column position from the full model select list, while
the inner union branches selected only `pk`. That mismatch produces SQL such as
`ORDER BY (4)` against a one-column select list.

## Files changed

`repo/django/db/models/sql/query.py`

Cloned each query in `combined_queries` from `Query.clone()`. This keeps the component
queries of a cloned combined queryset independent from the original queryset, preserving
the usual queryset immutability contract for later operations such as `values()`,
`values_list()`, and `order_by()`.

## Assumptions and alternatives

I assumed the intended behavior is that deriving and evaluating a queryset from a combined
queryset must not mutate or otherwise change later evaluation of the original combined
queryset.

I considered changing only the SQL compiler path that applies a combined queryset's
selected columns to each branch. That path already performs a local clone before
`set_values()`, and a compiler-only fix would still leave other future branch-level
mutations vulnerable to the same shared-state problem. Cloning `combined_queries` in
`Query.clone()` addresses the ownership issue at the boundary where queryset derivation
occurs.

I also considered cloning component queries when constructing the initial combined query
in `QuerySet._combinator_query()`. That would not fix clones of an already-combined
queryset unless `Query.clone()` also handled nested queries, so the smaller and more
central fix is in `Query.clone()`.
