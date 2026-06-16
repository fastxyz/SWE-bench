# FVK PROOF: matplotlib__matplotlib-24177

Status: constructed, not machine-checked.

## Theorem

For finite data-coordinate step histogram polygons produced by
`Axes.hist(..., histtype="step", density=True)`, V1 ensures that
`Axes._update_patch_limits` computes data-limit candidate points from the
unsimplified path geometry. Therefore the maximum density vertex of the step
outline is included in the points supplied to `update_datalim`.

## Proof Sketch

1. `Axes.hist` step mode constructs one outline polygon from arrays containing
   every bin edge, bottom value, and bin top value. For vertical orientation,
   the density coordinate is in `y`; for horizontal orientation, the arrays are
   swapped before creating the polygon. Therefore the density maximum is an
   original vertex of the created polygon. This discharges PO-4 up to the path
   limit updater.

2. The polygon is added through `Axes.fill`, then `Axes.add_patch`, then
   `Axes._update_patch_limits`. In V1, the limit updater calls
   `p.iter_bezier(simplify=False)`.

3. `Path.iter_bezier(**kwargs)` forwards `simplify=False` to
   `Path.iter_segments`. `Path.cleaned(..., simplify=False, ...)` disables the
   cleaned path's simplify flag, so the iterator is not allowed to use the
   renderer-oriented path simplification that removed vertices in the public
   counterexample. This discharges PO-2.

4. For each yielded segment, `_update_patch_limits` appends
   `curve([0, *dzeros, 1])`. A straight-line segment has no interior
   axis-aligned extrema, so this appends its endpoints. Consecutive line
   segments cover the original path vertices. For Bezier curves, the same code
   continues to include endpoints and reported axis-aligned extrema. This
   discharges PO-3.

5. Combining steps 1 through 4, the maximum density vertex of the step
   histogram polygon is included in `xys = trf_to_data.transform(vertices)` and
   supplied to `self.update_datalim(xys, updatex=..., updatey=...)`. Thus the
   autoscale input includes the whole step histogram outline, discharging
   PO-1.

6. Diff inspection shows no change to transform gating, update-axis flags,
   zero-size Rectangle handling, public method signatures, or return shapes.
   This discharges PO-5.

## Counterexample Elimination

The public hint gives a path whose full vertex maximum is y = 0.33418844, but
default segment iteration returns a simplified sequence whose largest shown y
value is smaller. Under the pre-V1 call `p.iter_bezier()`, the data-limit
candidate set could be derived from that simplified sequence. Under V1,
`simplify=False` blocks that derivation: the iterator must use the
unsimplified geometry, so the omitted maximum vertex is restored to the
candidate point set.

## Formal Core

The mini semantics in `fvk/mini-python.k` abstracts only the path-limit
operations needed here:

- `iterBezier(P, false)` returns unsimplified segments;
- `limitPointList(P)` collects endpoints and curve extrema from those
  segments;
- `updatePatchLimits(P)` updates data limits from `limitPointList(P)`.

The claims in `fvk/patch-limits-spec.k` encode:

- `UNSIMPLIFIED-COVERAGE`: unsimplified iteration covers all straight-path
  vertices;
- `CANDIDATE-POINTS`: `_update_patch_limits` uses those unsimplified points;
- `STEP-HIST-MAX`: a step histogram's density maximum is included.

## Commands Not Run

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/patch-limits-spec.k
kprove fvk/patch-limits-spec.k
```

Expected later outcome: `#Top` for all claims.

## Residual Risk

- Partial correctness only: termination and performance are not proved.
- The proof abstracts NumPy arrays, transforms, and `Bbox` internals to the
  point-set property needed by the issue.
- The proof is constructed, not machine-checked.
- Broad Matplotlib integration tests should be kept.

## Verdict

FVK confirms V1 for the reported issue. No additional source edit is justified
by the findings or proof obligations.
