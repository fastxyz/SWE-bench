# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims

The formal claims are in `admin-search-spec.k`.

Claim C1, nonempty terms: `adminSearch(LS, TS, DUP)` reaches
`result(qand(clausesFor(TS, LS)), 1, DUP)` when `TS` is nonempty.

Claim C2, empty terms: `adminSearch(LS, .List, DUP)` reaches
`result(qtrue, 0, DUP)`.

## Proof sketch

1. `construct_search()` is unchanged, so every configured search field maps to
   the same ORM lookup path as before. This discharges O2.

2. For each token from `smart_split(search_term)`, the code still unescapes a
   fully quoted token and constructs:

   ```python
   models.Q(
       *((orm_lookup, bit) for orm_lookup in orm_lookups),
       _connector=models.Q.OR,
   )
   ```

   Therefore each token contributes exactly one OR over all ORM lookups. This
   discharges O1 and the per-token half of O3.

3. V2 appends every per-token OR clause to `term_queries` and performs no
   queryset filtering inside the loop. The only search-term filter call is:

   ```python
   queryset = queryset.filter(*term_queries)
   ```

   guarded by `if term_queries`. Positional `Q` arguments to `filter()` are
   ANDed by `QuerySet._filter_or_exclude_inplace()` via `Q(*args, **kwargs)`.
   This discharges the AND-across-terms half of O3 and the one-filter property
   O4.

4. Source inspection of the ORM path shows the one filter call invokes one
   `Query.add_q()`, which calls `_add_q(q_object, self.used_aliases)` and passes
   the same alias-reuse set while building child clauses. Normal chained filters
   clone through `Query.chain()`, which clears `used_aliases` when
   `filter_is_sticky` is false. V2 therefore removes the issue's per-token
   chained-filter mechanism. This discharges O5 at source level.

5. The duplicate flag block is unchanged and still evaluates
   `lookup_spawns_duplicates()` over the constructed lookups. This discharges
   O6.

6. The method signature and return statement remain unchanged. This discharges
   O7.

7. If no terms are produced, `term_queries` is empty and V2 performs no filter
   call. This discharges O8.

## Machine-check commands, not executed

```sh
kompile fvk/mini-admin-search.k --backend haskell
kast --backend haskell fvk/admin-search-spec.k
kprove fvk/admin-search-spec.k
```

Expected result after a future machine check: `kprove` returns `#Top` for the
two claims, modulo the adequacy of the mini semantics.

## Residual risk

- The proof is partial correctness over the query-construction unit. It does not
  prove database planner performance or queryset evaluation termination.
- The mini K semantics abstracts Django ORM internals to the filter-count and
  Boolean-predicate properties needed for this issue.
- The proof is constructed, not machine-checked.

## Test guidance

No tests were run or modified. Tests that assert the documented AND-of-ORs
result membership for simple local fields are candidates for proof subsumption
only after machine checking. Tests for actual SQL alias counts, database backend
behavior, duplicate handling, and admin integration should be kept.
