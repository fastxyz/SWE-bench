# Iteration Guidance

Status: constructed, not machine-checked.

## Verdict

V1 stands unchanged.

The FVK audit found the original baseline bug (FI-1) and confirmed that the V1
slice-bound arithmetic discharges the public centered-iteration intent (FI-2),
the even-window corner case (FI-3), edge clipping and `min_periods` framing
(FI-4), and compatibility constraints (FI-5).

## Recommended Code Action

No additional production-code edit is justified. In particular:

- Do not replace iteration with `construct()`: FI-4 and PO-7 show the existing
  view-slice plus mask structure is sufficient and less invasive.
- Do not change the offset to `W // 2`: FI-3 shows that would break even
  centered windows.
- Do not alter labels, return shape, or multidimensional behavior: PO-6 and
  PO-8 require preserving them.

## Recommended Verification Action

When a K environment is available, run:

```sh
cd fvk
kompile mini-python-rolling.k --backend haskell
kast --backend haskell rolling-iter-spec.k
kprove rolling-iter-spec.k
```

Expected result: `#Top`.

## Recommended Test Action

Do not edit tests in this benchmark task. For upstream development, add focused
tests for:

- manual iteration with `center=True`, `window=3`, matching direct rolling
  means;
- manual iteration with `center=True`, an even window such as `window=4`, to
  guard the `(W - 1) // 2` offset convention.

Keep integration and compatibility tests; the proof only covers the bound
calculation and immediate iterator frame conditions.
