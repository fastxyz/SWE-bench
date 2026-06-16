# Formal Spec English

Status: constructed for FVK audit; not machine-checked.

The K claims in `rolling-iter-spec.k` say:

- FE-1: For any data length `N`, positive window `W`, and in-range output
  index `I`, `rollingBounds(N, W, false, I)` reaches
  `pair(max(I - (W - 1), 0), min(I + 1, N))`. In words, non-centered rolling is
  right-aligned and clipped to the data extent.
- FE-2: For any data length `N`, positive window `W`, and in-range output
  index `I`, `rollingBounds(N, W, true, I)` reaches
  `pair(max(I - W // 2, 0), min(I + (W - 1) // 2 + 1, N))`. In words,
  centered rolling uses the same left/right padding convention as
  `Variable.rolling_window`.
- FE-3: The algebraic simplification used by FE-2 is that
  `I + 1 + ((W - 1) // 2) - W == I - (W // 2)` for `W > 0`, so V1's
  offset-from-right calculation is exactly the construction-path left bound.
- FE-4: For the issue's concrete `N=9`, `W=3`, `center=True`, the first,
  second, and last iterator bounds are `[0:2]`, `[0:3]`, and `[7:9]`. With
  default `min_periods=3`, those bounds produce `nan`, `2`, and `nan` for the
  respective manual means, matching the centered reduction edges.
