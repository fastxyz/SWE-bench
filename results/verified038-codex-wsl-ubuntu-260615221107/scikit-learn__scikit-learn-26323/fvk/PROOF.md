# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were run.

## Reproduce The Machine Check Later

From the workspace root, the intended commands are:

```sh
kompile fvk/mini-column-transformer.k --backend haskell
kast --backend haskell fvk/column-transformer-set-output-spec.k
kprove fvk/column-transformer-set-output-spec.k
```

Expected result after a successful machine check: `#Top`.

## Proof Sketch

### `REMAINDER-PROPAGATED`

Start with `ct(outDefault, estimator, outDefault, outDefault)` and apply
`setOutput(..., pandas)`.

1. `setOutput` rewrites to `setRemainder(setExplicit(..., pandas), pandas)`.
2. `setExplicit(..., pandas)` rewrites explicit output to `outPandas` and the
   self output to `outPandas`.
3. `setRemainder(... estimator ..., pandas)` rewrites remainder output to
   `outPandas`.
4. The final state is
   `ct(outPandas, estimator, outPandas, outPandas)`.

This discharges PO-1.

### `CLONED-REMAINDER-PANDAS`

The first claim establishes that after `setOutput(..., pandas)`, the abstract
remainder output is `outPandas`. `cloneRemainderOutput` returns the stored
remainder output, modeling `clone` copying `_sklearn_output_config`. Therefore
the fit-time clone is pandas-configured.

This discharges PO-2.

### `PANDAS-HSTACK`

Substitute the result of `CLONED-REMAINDER-PANDAS` into
`hstackBranch(outPandas, outPandas, remainderCloneOutput)`. The first
`hstackBranch` rule matches only when all three outputs are `outPandas`, so the
branch rewrites to `usePandas`.

This discharges PO-3.

### `SENTINEL-UNCHANGED`

For `ct(outDefault, sentinel, outDefault, outDefault)`, `setExplicit` still
sets explicit output and self output to `outPandas`. The sentinel-specific
`setRemainder` rule leaves the remainder output unchanged.

This discharges PO-6.

### `NONE-NOOP`

For `transform=None`, `setExplicit` and `setRemainder` leave child outputs
unchanged. In source, `_safe_set_output` now returns before checking for a
child `set_output`, so the documented no-op behavior holds for the helper as
well.

This discharges PO-4.

## Proof-Derived Findings

- F-001: V1 correctly fixed the issue-relevant propagation gap.
- F-002: V1 exposed a helper no-op edge for `transform=None`; V2 fixes it.
- F-003: The non-`None` unconfigurable-transformer error remains intact.

## Test Recommendations

No tests were modified. Because the proof is not machine-checked, no existing
tests should be removed on the basis of this FVK pass. Useful tests to add in a
normal development environment would cover:

- pre-fit `ColumnTransformer.set_output("pandas")` with
  `remainder=VarianceThreshold()`;
- `_safe_set_output` with `transform=None` on an estimator that has
  `transform` but no `set_output`;
- `_safe_set_output` still raising for the same estimator with
  `transform="pandas"`.
