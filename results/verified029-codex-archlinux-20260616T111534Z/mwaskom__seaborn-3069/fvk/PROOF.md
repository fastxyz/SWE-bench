# PROOF

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## What is proved

For each coordinate axis processed by `Plotter._finalize_figure`:

- if its compiled scale is `Nominal`, its grid is disabled;
- if it is nominal x, has `n > 0` categories, and has no explicit user limit,
  its limits become `(-0.5, n - 0.5)`;
- if it is nominal y, has `n > 0` categories, and has no explicit user limit,
  its limits become `(n - 0.5, -0.5)`;
- if it is nominal y with an explicit user limit, the user limit is applied and
  the axis ends inverted;
- if it is not nominal, the nominal default policy does not apply.

## Proof sketch

The formal model in `mini-python-axis.k` reduces finalization to one
property-complete axis-state transition:

`axisState(axis, scale, limitKind, lo, hi, n, grid, inverted, limits)`.

The transition rules mirror the V1 branch structure:

1. `scale == Nominal` first sets `grid` to `false`.
2. If a user limit exists, the limit branch applies `(lo, hi)`.
3. In the nominal y explicit-limit branch, normal-order limits are inverted and
   already-inverted limits are preserved.
4. If no user limit exists and `n > 0`, the nominal default branch sets doubled
   half-step limits: x gets `lim(-1, 2*n - 1)`, y gets
   `lim(2*n - 1, -1)`.
5. If `scale != Nominal`, the nominal-specific grid, default-limit, and
   inversion rules are not applied.

The real `_finalize_figure` loop is handled by the invariant: after processing
the first `k` subplot axes, all processed nominal axes satisfy the matching
postcondition above, all processed non-nominal axes satisfy the frame condition,
and unprocessed axes remain outside the processed prefix. One more loop body
step applies the one-axis transition to axis `k + 1`, preserving the invariant.
At loop exit, every subplot axis has been processed.

Arithmetic verification conditions are limited to the half-step encoding:
`-.5 == -1 / 2` and `n - .5 == (2*n - 1) / 2`, represented with doubled
integers. The only side condition for default limits is `n > 0`.

## Adequacy gate

`FORMAL_SPEC_ENGLISH.md` paraphrases every K claim. `SPEC_AUDIT.md` compares
those claims against `INTENT_SPEC.md`. All required issue behavior passes. The
empty-axis boundary is marked ambiguous and non-blocking because public intent
does not specify it.

`PUBLIC_COMPATIBILITY_AUDIT.md` found no changed public signature, public
callsite requirement, or override compatibility issue.

## Machine-check commands

These commands are emitted for later machine checking; they were not run:

```sh
kompile fvk/mini-python-axis.k --backend haskell
kast --backend haskell fvk/nominal-axis-spec.k
kprove fvk/nominal-axis-spec.k
```

Expected machine-check outcome after syntax/toolchain validation: `#Top` for
the stated claims.

## Test guidance

No test removal is recommended. The proof is constructed but not
machine-checked, and the model abstracts Matplotlib integration details. Keep
integration tests around actual rendered axes, especially for inferred nominal
scales, paired/faceted axes, explicit `Plot.limit`, and grid visibility.
