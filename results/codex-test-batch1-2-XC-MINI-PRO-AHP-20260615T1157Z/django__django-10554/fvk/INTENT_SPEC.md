# Intent Spec

Status: constructed, not machine-checked.

## Required behavior from public intent

I-1. A queryset produced by `union()` and ordered by a selected model column must
remain evaluable after a derived queryset such as `qs.order_by().values_list()`
is created and evaluated.

Evidence: `benchmark/PROBLEM.md` says "Union queryset with ordering breaks on
ordering with derived querysets" and shows `qs.order_by().values_list('pk',
flat=True)` followed by re-evaluating `qs` raising `ProgrammingError`.

I-2. Derived queryset operations must not mutate the query state that the source
queryset later depends on.

Evidence: the public hint says the bug "looks like a bug caused by a .query
attribute change without performing a prior copy() of the query/queryset."

I-3. For a combined query, narrowing the selected columns for a derived
`values()` or `values_list()` queryset may affect the derived queryset's
component queries, but it must not affect the original combined queryset's
component queries.

Evidence: the issue's failing SQL orders by position 4 after the derived query
selected only `pk`; the original ordered union still needs its original
multi-column select list.

I-4. The fix must preserve existing public API shape.

Evidence: the issue requests a behavior fix, not a new public method, signature,
return type, or new user-facing API.

## Domain

The formal model covers combined Django `Query` objects with two component
queries. This is enough for the reported `union()` reproduction and for the
aliasing property because extra components are handled pointwise by the same
clone rule. The model abstracts SQL text, model fields, and database execution
down to the observable property that failed: whether every component select list
still contains the ordered column position.
