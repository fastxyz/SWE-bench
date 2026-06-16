# FVK PROOF

Status: constructed, not machine-checked. No commands were executed.

## Contract Proved

For the local `_make_image` lower-limit repair:

- If the norm is `LogNorm` and the temporary lower limit is non-positive, the
  adjusted lower limit is a positive dtype epsilon.
- If the norm is `LogNorm` and the temporary lower limit is already positive,
  the adjusted lower limit is unchanged.
- If the norm is not `LogNorm`, the local branch leaves the lower limit
  unchanged.

This is a partial-correctness proof for the local guard abstraction only.

## Symbolic Proof

Let `S` be the finite temporary lower limit and let `EPS` be
`np.finfo(scaled_dtype).eps`, with `EPS > 0`.

Case 1: `isLog == true` and `S <= 0`.

The V1 source enters the repair branch and sets the adjusted limit to
`max(S, EPS)`. Since `S <= 0` and `EPS > 0`, `S < EPS`, so the result is `EPS`.
Therefore the adjusted lower limit is strictly positive. This covers both the
old negative case and the previously missed exact-zero case.

Case 2: `isLog == true` and `S > 0`.

The V1 source does not enter the repair branch. The result is `S`, and the
assumption gives `S > 0`. Existing positive-limit behavior is preserved.

Case 3: `isLog == false`.

The outer `isinstance(self.norm, mcolors.LogNorm)` guard is false, so the source
does not change `S`. Non-log normalization paths are preserved.

By case split over `isLog` and the sign of `S`, all formal claims in
`fvk/image-lognorm-spec.k` are covered.

## Why V1 Stands

F1 identifies the old bug as the missing zero boundary. PO3 requires zero to be
treated as an invalid lower log limit. V1 changes exactly that boundary from
`s_vmin < 0` to `s_vmin <= 0`.

The audit did not justify a broader edit. F4 and PO7 reject coercing arbitrary
non-finite limits because the public issue is about finite huge-range rescaling,
not changing `LogNorm`'s global invalid-limit policy. F2, F3, PO4, and PO5
confirm that V1 preserves already-valid log limits and non-log paths.

## Machine-Check Commands

These commands were not run:

```sh
kompile fvk/mini-image-lognorm.k --backend haskell
kast --backend haskell fvk/image-lognorm-spec.k
kprove fvk/image-lognorm-spec.k
```

Expected result after a real machine check: `kprove` returns `#Top` for the
claims in `fvk/image-lognorm-spec.k`.

## Test Guidance

No tests are recommended for removal. The constructed proof is local and not
machine-checked, while the public image test also covers renderer integration,
masked values, colormap behavior, and backend drawing.
