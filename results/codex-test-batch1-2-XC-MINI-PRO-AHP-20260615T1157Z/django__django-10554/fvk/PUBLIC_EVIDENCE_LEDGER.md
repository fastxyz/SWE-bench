# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | prompt | "Union queryset with ordering breaks on ordering with derived querysets" | Combined querysets must tolerate derived queryset creation/evaluation without corrupting the original ordered queryset. | Encoded by claim `ORDERED-UNION-DERIVED-VALUES-FRAME`. |
| E-2 | prompt traceback | `ProgrammingError: ORDER BY position 4 is not in select list` | The original ordered union must retain component select width at least equal to the order position after derived `values_list('pk')`. | Encoded as `assertOrderable(orig)`. |
| E-3 | prompt reproduction | `qs.order_by().values_list('pk', flat=True)` followed by `qs` breaks | The dangerous operation is derivation from an existing combined queryset, not a direct mutation requested by user code. | Encoded as `deriveValuesPk(orig, derived, d1, d2)` followed by `assertOrderable(orig)`. |
| E-4 | public hint | ".query attribute change without performing a prior copy() of the query/queryset" | The repair should establish copy-before-mutation for query state reachable from combined queries. | Encoded as deep cloning of component queries in `deriveValuesPk`. |
| E-5 | source code | `QuerySet._clone()` calls `self.query.chain()`, and `Query.chain()` calls `Query.clone()` | `Query.clone()` is the derivation boundary that must produce independent combined children. | Justifies changing `Query.clone()`. |
| E-6 | source code | `get_combinator_sql()` may clone and `set_values()` on component compiler queries when the columns list is limited | The formal model must include component select-list narrowing as the mutation to frame away from the original. | Encoded as derived child widths becoming 1. |
| E-7 | source code | `QuerySet._combinator_query()` stores `combined_queries` and later queryset methods derive by cloning | Public construction behavior should remain unchanged; the required isolation is at derivation time. | Supports keeping V1's edit in `Query.clone()` and not changing `_combinator_query()`. |
| E-8 | task constraints | "Do not modify any test files" and "do not attempt to run tests" | FVK must write commands/artifacts and reason about expected outcome without execution or test edits. | Reflected in `PROOF.md` and `ITERATION_GUIDANCE.md`. |
