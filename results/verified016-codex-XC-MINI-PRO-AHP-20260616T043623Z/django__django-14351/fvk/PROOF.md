# Constructed Proof

Status: constructed, not machine-checked.

## What Is Proved

For the changed ORM grouping unit, the constructed proof establishes partial
correctness of `Query.get_group_by_cols()` against the spec in `fvk/SPEC.md`:

- Non-correlated nested raw `Query` expressions return no group-by columns.
- Scalar correlated raw `Query` expressions return their external columns.
- Possibly multivalued correlated raw `Query` expressions fall back to grouping
  by themselves.
- Explicit alias requests return `Ref(alias, self)`.

There are no loops or recursive calls in the changed unit, so no circularity
claim is needed.

## Proof Sketch

The mini semantics in `fvk/mini-orm-query.k` is a property-complete abstraction
of the changed method. It keeps the axis the bug depends on: whether group-by
collection receives `selfQuery` or receives only dependency columns. A passing
instance maps to `.Exprs`; the pre-fix failing behavior maps to
`selfQuery ; .Exprs`, so the abstraction distinguishes pass from fail.

Claim C-001 rewrites `getGroupByCols(none, .Exprs, false)` through the
non-alias, non-multivalued rule to `.Exprs`. This discharges PO-002. Combined
with the existing `Lookup.get_group_by_cols()` behavior, this discharges PO-007:
the lookup branch contributes only its LHS group-by columns, not the RHS raw
subquery.

Claim C-002 rewrites `getGroupByCols(none, extCol(1, false) ; .Exprs, false)`
to the unchanged external-column sequence. This discharges PO-003 and preserves
scalar correlated subquery dependencies.

Claim C-003 rewrites `getGroupByCols(none, extCol(1, true) ; .Exprs, true)` to
`selfQuery ; .Exprs`. This discharges PO-004 and preserves Django's existing
possibly-multivalued fallback.

Claim C-004 rewrites `getGroupByCols(alias(A), CS, HAS_MULTI)` to
`ref(alias(A)) ; .Exprs`. This discharges PO-005 and preserves explicit alias
handling.

PO-006 is discharged by source inspection: the Python method only calls
`get_external_cols()` and returns a list. It does not mutate select state or
rewrite the nested query.

## Machine-Detailed Shape

Each claim is a one-step reachability proof by Axiom plus framing:

1. Match the `<k>` cell against one of the three semantic rules in
   `mini-orm-query.k`.
2. Rewrite the head expression to the specified result.
3. No side conditions, loops, maps, or arithmetic VCs remain.

The integration proof for PO-007 is a Consequence step over the existing source:
`Lookup.get_group_by_cols()` extends the LHS list with RHS group-by columns.
By PO-002 the RHS list is empty for the reported non-correlated subquery, so the
result contains no raw RHS `Query` expression.

## Run Commands

These commands are recorded only; this task forbids executing them.

```sh
kompile fvk/mini-orm-query.k --backend haskell
kast --backend haskell fvk/query-group-by-spec.k
kprove fvk/query-group-by-spec.k
```

Expected machine-check result, if run in a suitable K environment: `#Top` for
all claims.

## Test Recommendation

Do not remove tests. This proof is constructed, not machine-checked, and the
task forbids modifying test files. A future public regression test should cover
the issue shape: an annotated queryset with an `OR` between a related
`__in=<queryset>` predicate and an aggregate predicate, asserting the RHS
subquery is not added to `GROUP BY` with default columns.

## Residual Risk

The proof is over a focused mini semantics, not full Python or full Django SQL
compilation. It is adequate for the defect axis because it preserves the exact
observable under audit: whether the RHS `Query` object itself is returned as a
group-by expression. Broader ORM behaviors remain covered by Django's existing
tests and are not candidates for test removal.
