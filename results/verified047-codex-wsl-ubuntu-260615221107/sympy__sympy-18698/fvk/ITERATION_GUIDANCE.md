# Iteration Guidance

## Source Decision

V1 stands unchanged after FVK audit.

Reason:

- F-001 and PO-1/PO-2 show that V1 fixes the reported univariate grouping
  defect.
- PO-3 through PO-6 show that V1 preserves the important surrounding API shapes.
- F-002 and PO-7 show that broad multivariate no-generator behavior remains
  underspecified and should not be changed in this pass.

## Recommended Future Work

1. Add public tests for the reported univariate case:
   `sqf_list((x**2 + 1)*(x - 1)**2*(x - 2)**3*(x - 3)**3, x)`.

2. Add a test that `factor_list()` is unaffected by square-free grouping.

3. Add tests for `sqf_list(..., polys=True)` and `sqf_list(..., frac=True)` with
   repeated square-free exponents.

4. Ask for an API decision on no-generator multivariate square-free calls:
   preserve legacy symbolic behavior, raise `ValueError`, or require exactly one
   generator.

5. If the API decision is to require univariate input strictly, implement that
   as a separate behavior-changing patch with public compatibility notes.

## Commands Recorded But Not Run

```sh
kompile fvk/mini-sqf.k --backend haskell
kast --backend haskell fvk/sqf-list-spec.k
kprove fvk/sqf-list-spec.k
```

No test files should be modified for this task.
