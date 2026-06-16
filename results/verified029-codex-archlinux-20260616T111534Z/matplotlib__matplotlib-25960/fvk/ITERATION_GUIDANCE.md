# FVK Iteration Guidance

Status: constructed from public intent and static source inspection; not
machine-checked.

## Code Decision

Do not keep V1 unchanged. F2 found that V1 read generic GridSpec subplot
spacing and therefore changed `add_subfigure(gs[i])` behavior beyond the
public intent. V2 is the recommended revision:

- Store `Figure.subfigures` spacing kwargs on the created GridSpec as
  `_subfigure_wspace` and `_subfigure_hspace`.
- Use only those private attributes in manual subfigure placement.
- Preserve GridSpec `wspace` and `hspace` for constrained-layout consumers.

## Suggested Public Tests To Add Later

Do not edit tests in this task. Recommended tests for a future normal
development pass:

1. `fig.subfigures(2, 2, wspace=0.2, hspace=0.2)` has positive horizontal and
   vertical gaps between adjacent subfigure bboxes.
2. `fig.subfigures(2, 2, wspace=0, hspace=0)` has zero gaps.
3. `fig.subfigures(1, 2, width_ratios=[1, 2], wspace=0.2)` preserves the ratio
   formula while inserting the expected separator.
4. `fig.add_gridspec(1, 2, wspace=0.5)` followed by
   `fig.add_subfigure(gs[0])` does not use the generic GridSpec `wspace` as
   manual subfigure spacing.
5. A constrained-layout smoke/image test continues to accept
   `subfigures(..., wspace=..., hspace=...)`.

## Proof Follow-Up

Run the machine-check commands only in an environment with K installed:

```sh
kompile fvk/mini-subfigure-layout.k --backend haskell
kast --backend haskell fvk/subfigure-layout-spec.k
kprove fvk/subfigure-layout-spec.k
```

Do not remove or relax tests based on this FVK pass until the claims are
machine-checked.

## Residual Risks

- The proof models exact normalized arithmetic, not Python floating-point
  rounding.
- The proof does not extend GridSpec validation for negative spacing, zero-sum
  ratios, or denominator-zero cases.
- The proof is partial correctness of the layout calculation; it does not prove
  rendering, backend behavior, or performance.
