# FVK PROOF OBLIGATIONS: matplotlib__matplotlib-24177

Status: constructed, not machine-checked.

## PO-1: Intent adequacy

Claim: the formal contract covers the public issue's observable, not merely the
candidate implementation.

Must show:

- The domain includes long straight-line step polygons created by
  `Axes.hist(..., histtype="step", density=True)`.
- The postcondition states that all original step vertices, including the
  density maximum, are included in the point set supplied to data-limit update.
- The spec rejects default path simplification as a valid source for data
  limits when it drops original data vertices.

Evidence: SPEC I-1 through I-4.

Status: discharged by SPEC.md and F-001/F-003.

## PO-2: Unsimplified iterator coverage

Claim: for a finite path `P`, calling `P.iter_bezier(simplify=False)` prevents
the path-cleanup stage from simplifying away original vertices.

Source facts:

- `Path.iter_bezier(**kwargs)` forwards keyword arguments to
  `Path.iter_segments(**kwargs)`.
- `Path.iter_segments(..., simplify=None, ...)` may use `Path.should_simplify`.
- `Path.cleaned(..., simplify=False, ...)` sets the cleaned path's
  `_should_simplify` flag to `False`.

Obligation:

```text
forall finite straight path P with vertices V:
  endpoints(iter_bezier(P, simplify=False)) contains every vertex in V
```

Status: discharged by source inspection and represented by
`PATCH-LIMITS-SPEC.UNSIMPLIFIED-COVERAGE`.

## PO-3: Candidate point coverage

Claim: `_update_patch_limits` includes every unsimplified line endpoint and
Bezier axis-aligned extrema in the points it transforms and passes to
`update_datalim`.

Source facts:

- The loop is:
  `for curve, code in p.iter_bezier(simplify=False):`
- For each curve it computes `dzeros = curve.axis_aligned_extrema()[1]`.
- It appends `curve([0, *dzeros, 1])`, which includes both endpoints and all
  reported interior extrema.

Obligation:

```text
limit_points(P) =
  union over unsimplified Bezier segments C in P of C({0, 1} union extrema(C))
```

Status: discharged by source inspection and represented by
`PATCH-LIMITS-SPEC.CANDIDATE-POINTS`.

## PO-4: Step histogram maximum inclusion

Claim: for the step histogram polygon, the histogram density maximum is one of
the original straight-line path vertices and is therefore included in
`limit_points(P)`.

Source facts:

- Step mode assigns the top of each bin into `y[1:...:2]` and
  `y[2:...:2]`.
- Vertical orientation uses `xvals.append(x.copy())` and
  `yvals.append(y.copy())`.
- Horizontal orientation swaps those arrays, so the same geometric point is
  present with axes exchanged.
- `self.fill(...)` creates the `Polygon` that is later added through
  `_update_patch_limits`.

Obligation:

```text
max_density(tops + bottom) in axis_projection(limit_points(step_path))
```

Status: discharged by source inspection and represented by
`PATCH-LIMITS-SPEC.STEP-HIST-MAX`.

## PO-5: Frame and compatibility

Claim: V1 changes only the simplification option for the path-limit iterator.

Must show unchanged:

- zero-size Rectangle skip;
- `contains_branch_seperately(self.transData)` gating;
- rectilinear/non-rectilinear x/y update flag adjustments;
- transform from patch coordinates to data coordinates;
- call to `update_datalim`;
- public method signatures and return shapes.

Status: discharged by diff inspection and F-005.

## PO-6: Residual proof boundary

Claim: the constructed proof is intentionally scoped to the issue-producing
observable and does not certify all Matplotlib patch limit behavior.

Must preserve:

- proof honesty: constructed, not machine-checked;
- no deletion of tests;
- no claim that arbitrary transforms, backends, or patch subclasses are fully
  verified.

Status: recorded in F-004 and PROOF.md.

## PO-7: No-execution compliance

Claim: verification commands and expected outcomes are recorded but not run.

Commands:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/patch-limits-spec.k
kprove fvk/patch-limits-spec.k
```

Expected later outcome: `kprove` returns `#Top` for the constructed claims.

Status: recorded in F-006.
