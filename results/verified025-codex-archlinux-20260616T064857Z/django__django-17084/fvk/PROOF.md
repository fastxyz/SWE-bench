# Constructed Proof

Status: constructed, not machine-checked.

## Claims Proved in the Mini Model

The formal artifacts are:

- `fvk/mini-django-query.k`
- `fvk/get-aggregation-spec.k`

The spec has four claims:

1. `window-ref-forces-wrapper`: when `refs_window` is true, the aggregate
   decision is `Wrapped`.
2. `window-ref-produces-safe-sql-shape`: in the reported minimal case where the
   only trigger is `refs_window`, the SQL shape is `SafeOuterAlias`.
3. `existing-trigger-still-wraps`: any pre-existing trigger still wraps.
4. `no-trigger-remains-direct`: when no trigger is true, the decision remains
   `Direct`.

## Proof Sketch

The mini semantics models the decision as:

```text
Wrapped iff group_by_tuple or is_sliced or has_existing_aggregation or
refs_subquery or refs_window or qualify or distinct or combinator.
```

The V1 source implements this same disjunction at
`repo/django/db/models/sql/query.py:455-464`, with `refs_window` computed from
aggregate refs at `repo/django/db/models/sql/query.py:419-427`.

For `window-ref-forces-wrapper`, symbolic execution starts with
`aggregateDecision(..., refs_window=true, ...)`. The wrapper rule's side
condition reduces to true because the disjunction contains `refs_window`; the
configuration rewrites to `Wrapped`.

For `window-ref-produces-safe-sql-shape`, symbolic execution expands
`aggregateSqlShape(false, false, false, false, true, false, false, false)` into
the decision plus a continuation. The decision rewrites to `Wrapped`, then
`compileAggregate(Wrapped, true)` rewrites to `SafeOuterAlias`. This corresponds
to preserving `Ref("cumul_DJR", ...)` in the outer aggregate while selecting the
window annotation in the inner query.

For `existing-trigger-still-wraps`, the same wrapper rule fires for any state
whose pre-existing trigger disjunction is true. This proves V1 did not remove
any old wrapping reason.

For `no-trigger-remains-direct`, the direct rule's negated disjunction side
condition holds, so the decision rewrites to `Direct`. This proves V1 does not
wrap queries with no wrapping reason.

There are no loops in this model, so no circularity claim is required.

## Expected Machine Check Commands

These commands were not executed in this session:

```sh
cd fvk
kompile mini-django-query.k --backend haskell
kast --backend haskell get-aggregation-spec.k
kprove get-aggregation-spec.k
```

Expected outcome after a real machine check: `kprove` returns `#Top`.

## Residual Risk

This proof is partial and model-level. It verifies the branch decision and
alias-vs-inline SQL shape that caused the issue. It does not prove full Django
SQL compilation, backend behavior, database execution, result conversion, or
termination.

Direct `Aggregate(Window(...))` expression lifting is not claimed. See Finding
F2 and PO6.

## Test Recommendation

Do not remove tests. Add or keep focused tests for:

- aggregating over a selected window annotation;
- aggregating a regular field and a selected window annotation in the same
  `aggregate()` call;
- a wrapped window annotation inside `Coalesce()`;
- a no-window annotation aggregation to guard that direct-path behavior remains
  available where no wrapper trigger is present.

Any future test-redundancy claim is conditional on machine-checking these K
claims and running Django's test suite in a real environment.
