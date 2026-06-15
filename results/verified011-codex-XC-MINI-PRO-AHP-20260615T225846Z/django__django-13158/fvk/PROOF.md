# Constructed Proof

Status: constructed, not machine-checked. The following commands are provided
for later checking only and were not executed:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/django-query-none-spec.k
kprove fvk/django-query-none-spec.k
```

## Claims

C1. `asSql(setEmpty(Q), SUPPORTS)` reaches `emptyResult` for every modeled query
`Q` and backend support flag `SUPPORTS`.

C2. `executeSql(setEmpty(Q), SUPPORTS, multi)` reaches `rows(0)` and leaves the
cursor count unchanged.

C3. The optional-empty `ModelMultipleChoiceField` path produces `setEmpty(Q)`;
therefore any later multi-result execution reaches `rows(0)`.

C4. For non-empty combined queries, the repair is framed away: backend support
checks and combined SQL assembly are unchanged.

## Symbolic Proof Sketch

For C1, expand `setEmpty(Q)` using the `SET-EMPTY` function rule. The resulting
query has `EMPTY = true`. Symbolically execute `asSql(query(true, C, Qs),
SUPPORTS)`. The `AS-SQL-EMPTY` rule fires before the combinator-support rules,
rewriting the computation to `emptyResult`. The proof does not inspect `C`,
`Qs`, or `SUPPORTS`, so it covers ordinary queries, supported combined queries,
and unsupported combined queries.

For C2, symbolically execute
`executeSql(setEmpty(Q), SUPPORTS, multi)`. The execution first schedules
`asSql(setEmpty(Q), SUPPORTS)` followed by `finishExecute(multi)`. By C1, the
head becomes `emptyResult`. The `EXEC-EMPTY-MULTI` rule rewrites this to
`rows(0)` and does not update the `<cursors>` cell. This models Django's
existing `execute_sql()` catch of `EmptyResultSet` before cursor creation.

For C3, the form empty-value producer is modeled as `cleanEmpty(Q) =>
setEmpty(Q)`. C2 then proves that evaluating the resulting queryset as a
multi-result query returns zero rows.

For C4, case split on `EMPTY = false`. The `AS-SQL-EMPTY` rule is inapplicable.
If the query has no combinator, the ordinary SQL rule applies. If it has a
combinator and `SUPPORTS = false`, the unsupported rule applies. If it has a
combinator and `SUPPORTS = true`, the combined SQL rule applies. These are the
same non-empty cases as before the repair.

## Proof-Derived Findings

F-02 came from C1's ordering requirement. V1 could prove "empty combined query
does not assemble operands" only after the backend-support branch had already
been passed. That was weaker than E3's empty-query contract, so V2 moved the
guard to `as_sql()`.

No additional code bug was found after V2. F-04 remains intentionally outside
the proven contract because public evidence requires empty result behavior, not
a changed operation-support matrix after combined queries.

## Test Recommendations

Do not delete or edit tests in this task.

After machine-checking, unit tests that assert `.none()` on a combined queryset
evaluates to zero rows, has count zero, or yields no objects through the optional
`ModelMultipleChoiceField` empty-value path would be subsumed by C1 through C3.
Integration tests for admin form saving, backend-specific set-operation support,
or operation support after `union().none()` should be kept because the formal
model abstracts those broader surfaces.
