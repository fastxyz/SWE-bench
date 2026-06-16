# Formal Spec English

Status: constructed from the K claims in `admin-search-spec.k`, not
machine-checked.

F1. For a nonempty finite token list and a finite lookup list,
`get_search_results()` constructs one OR clause per token. Each OR clause
contains exactly one atomic lookup predicate for each constructed ORM lookup.

F2. The final query predicate is the conjunction of all per-token OR clauses.
Equivalently, every token must match at least one configured lookup.

F3. For an empty token list, no search filter is applied. The input queryset is
returned unchanged except for ordinary queryset object identity/cloning details
outside the model.

F4. For a nonempty token list, exactly one queryset `filter` application is used
for all token clauses. The number of filter applications is independent of the
number of tokens.

F5. The single filter application submits all term clauses to one ORM
`add_q()` operation, allowing Django's normal alias reuse within that operation.

F6. Prefix shortcuts (`^`, `=`, `@`), explicit valid lookups, `pk` traversal,
and the default `icontains` suffix are preserved by the lookup construction
helper.

F7. The duplicate flag is true exactly when at least one constructed ORM lookup
path is reported by `lookup_spawns_duplicates()` as able to duplicate rows.

F8. The public method signature and tuple return shape of
`get_search_results(request, queryset, search_term)` are unchanged.
