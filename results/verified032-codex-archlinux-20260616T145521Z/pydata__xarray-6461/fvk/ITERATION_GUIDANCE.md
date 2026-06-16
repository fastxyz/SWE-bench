# Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decision

Do not change production code in this FVK pass. Findings F1 through F4 are closed by the existing V1 source change, and PO1 through PO5 are discharged by the constructed proof. PO6 remains an honesty-gate limitation, not a code defect.

## Suggested Future Tests

Do not edit tests in this task. For a future normal development pass, add focused public tests for:

1. `with xr.set_options(keep_attrs=True): xr.where(xr.DataArray([1, 2, 3]) > 0, 1, 0)` does not raise and has empty attrs.
2. `xr.where(cond, 1, y_with_attrs, keep_attrs=True)` has empty attrs, proving `y` is not a fallback source for scalar `x`.
3. `xr.where(cond, x_with_attrs, y, keep_attrs=True)` preserves attrs content from `x`.
4. The existing `keep_attrs=False`, string policy, and callable policy paths still behave as before.

## Machine-check Follow-up

Run the emitted commands in an environment with K installed:

```sh
kompile fvk/mini-python-where-attrs.k --backend haskell
kast --backend haskell fvk/xarray-where-attrs-spec.k
kprove fvk/xarray-where-attrs-spec.k
```

Until that succeeds, treat the proof as constructed but not machine-checked and keep all tests.
