# Proof

Status: constructed, not machine-checked.

## Claims

The K artifacts are:

- `fvk/mini-django-compiler.k`
- `fvk/django-14122-spec.k`

The main claims are:

- `GROUPED-META-SUPPRESSED`
- `UNGROUPED-META-PRESERVED`
- `GROUPED-EXPLICIT-PRESERVED`
- `GROUPED-EXTRA-PRESERVED`

## Constructed proof sketch

The mini semantics rewrites `compile(query(...))` according to the same
precedence structure as `SQLCompiler.get_order_by()`:

1. `extra_order_by` wins first.
2. explicit `query.order_by` wins next.
3. disabled default ordering with no explicit order produces no ordering.
4. metadata ordering is selected only for `noGroup`.
5. grouped metadata-only states produce no ordering source.

For `GROUPED-META-SUPPRESSED`, symbolic execution matches rule 5:

`compile(query(false, true, false, true, grouped, DISTINCT, DISTINCT_FIELDS))`

rewrites in one step to:

`result(noSource, false, false, false, false)`

This discharges PO-1 and PO-2. The result records that metadata is absent from
the selected ordering, absent from hidden distinct selects, absent from
`GROUP BY`, and absent from public `ordered` introspection.

For `UNGROUPED-META-PRESERVED`, symbolic execution matches rule 4:

`compile(query(false, true, false, true, noGroup, DISTINCT, DISTINCT_FIELDS))`

rewrites in one step to:

`result(metaSource, true, DISTINCT andBool notBool DISTINCT_FIELDS, false, true)`

This discharges PO-3 and shows the fix is not overbroad.

For `GROUPED-EXPLICIT-PRESERVED`, symbolic execution matches rule 2 for every
value of the default-ordering and metadata flags, yielding:

`result(explicitSource, false, false, false, true)`

For `GROUPED-EXTRA-PRESERVED`, symbolic execution matches rule 1 for every
value of the lower-precedence flags, yielding:

`result(extraSource, false, false, false, true)`

Together these discharge PO-4.

PO-5 is discharged by the `orderedProperty` component in the first two claims:
metadata-only default ordering is true for `noGroup` and false for `grouped`.
The corresponding code uses `self.query.group_by is None` in both
`SQLCompiler.get_order_by()` and `QuerySet.ordered`.

There are no loops or recursive calls in the modeled fragment, so no circularity
claim is needed.

## Exact machine-check commands

These commands were not run in this session.

```sh
kompile fvk/mini-django-compiler.k --backend haskell
kast --backend haskell fvk/django-14122-spec.k
kprove fvk/django-14122-spec.k
```

Expected machine-check result after a successful run: `#Top`.

## Residual risk

The proof is constructed over a mini semantics, not the full Python or full
Django runtime. The abstraction preserves the issue property because it keeps
ordering provenance and grouped state observable, but it does not prove SQL
string formatting, backend execution, or database result values.

No test-redundancy recommendation is made. The task forbids running or modifying
tests, and this proof is not machine-checked.
