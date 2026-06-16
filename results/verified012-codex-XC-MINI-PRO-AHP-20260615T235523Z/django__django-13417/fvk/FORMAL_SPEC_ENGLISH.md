# Formal Spec English

C1. `ORDERED-MATCHES-COMPILER`: For every abstract query state, the V1
`QuerySet.ordered` result equals the compiler-derived semantic orderedness
model.

C2. `GROUPED-META-UNORDERED`: For a non-empty query with no explicit ordering,
default ordering enabled, model `Meta.ordering` present, and `GROUP BY` active,
`QuerySet.ordered` returns `False`.

C3. `EXPLICIT-GROUPED-ORDERED`: For a grouped query with an explicit
`query.order_by` source, `QuerySet.ordered` returns `True`.

C4. `DEFAULT-NONGROUPED-ORDERED`: For a non-grouped query with default ordering
enabled and model `Meta.ordering` present, `QuerySet.ordered` returns `True`.

C5. `NO-EFFECTIVE-ORDERING-UNORDERED`: For a non-empty query with no explicit
ordering and no effective default model ordering, `QuerySet.ordered` returns
`False`.

C6. Frame condition: evaluating `QuerySet.ordered` reads query state and does not
modify the query or public API shape.
