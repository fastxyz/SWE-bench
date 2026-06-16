# Intent Spec

Status: constructed for FVK audit; not machine-checked.

Scope: `DataArrayRolling.__iter__` in `repo/xarray/core/rolling.py`, with
`Variable.rolling_window` and public rolling docs used as semantic references.

Intent-only obligations:

- IS-1: A manually iterated `DataArrayRolling` must respect the same rolling
  alignment selected by `center` as direct rolling reductions do.
- IS-2: With `center=False` or false-like `center`, aggregation labels remain at
  the end of each window, so the iterator is right-aligned.
- IS-3: With `center=True`, windows are center-justified. For a window size `W`
  at zero-based position `I`, the logical left padding is `W // 2` and the
  logical right padding is `(W - 1) // 2`.
- IS-4: Iterator windows are views/slices of the original object, so edge
  windows are clipped to valid data bounds rather than padded with materialized
  `nan` values; `min_periods` masking accounts for the shorter edge slices.
- IS-5: Iteration preserves the existing public surface: it yields
  `(label, window)` pairs, preserves labels, raises for multidimensional rolling,
  and does not change signatures or tests.

Concrete issue obligation:

- For `N=9`, `W=3`, `center=True`, manual means over iterator windows must align
  with the centered reduction sequence `[nan, 2, 3, 4, 5, 6, 7, 8, nan]`, not
  with the legacy right-aligned sequence `[nan, nan, 2, 3, 4, 5, 6, 7, 8]`.
