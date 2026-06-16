# FVK SPEC: matplotlib__matplotlib-24177

Status: constructed, not machine-checked.

## Target

Candidate fix V1 changes `Axes._update_patch_limits` in
`repo/lib/matplotlib/axes/_base.py` from:

```python
for curve, code in p.iter_bezier():
```

to:

```python
for curve, code in p.iter_bezier(simplify=False):
```

The audited unit is the patch data-limit update path used when
`Axes.hist(..., histtype="step", density=True)` creates a single step-outline
`Polygon` and adds that patch to the Axes.

## Intent Spec

I-1. Step histogram density autoscaling.

- Source: prompt.
- Evidence: "`ax.hist` density not auto-scaled when using
  `histtype='step'`"; "density axis ... is not automatically adjusted to fit
  the whole histogram."
- Obligation: for a finite step histogram polygon, the Axes data limits must
  include the full histogram outline, including the largest density value.
- Status: encoded by PO-2, PO-3, and PO-4.

I-2. Scaling data should not cause a step density-axis clipping artifact.

- Source: prompt.
- Evidence: "densities changes if you rescale the whole data array, which is
  counterintuitive as rescaling the data should only affect the x-axis values."
- Obligation: after histogram density values are computed, autoscaling must
  not drop the density maximum merely because the x-spacing or path shape
  changes.
- Status: encoded by PO-4.

I-3. Step and bar histograms should autoscale over equivalent histogram
geometry.

- Source: prompt and public hint.
- Evidence: "if you set `histtype='step'`, the issue will occur, but is
  otherwise okay"; "In bar mode, each bin is a Rectangle ... In step mode, all
  bins are combined into a single outline `Polygon`."
- Obligation: replacing per-bin rectangles with one outline polygon must not
  lose data-limit extrema.
- Status: encoded by PO-3 and PO-4.

I-4. Data limits must be computed from the unsimplified data geometry, not from
renderer-oriented path simplification.

- Source: public hint and `Path.iter_segments` docstring.
- Evidence: public hint shows `vertices max [4.93527997 0.33418844]` but
  default `iter_segments()` yields a much smaller vertex subset; docstring says
  `simplify` removes vertices that do not affect appearance.
- Obligation: data-limit computation must disable path simplification.
- Status: encoded by PO-1 and PO-2.

I-5. Bezier handling must be preserved.

- Source: `_update_patch_limits` comments and existing behavior.
- Evidence: "Loop through each segment to get extrema for Bezier curve
  sections"; `BezierSegment.axis_aligned_extrema()` returns interior extrema.
- Obligation: the fix must still include line endpoints and Bezier extrema in
  candidate limit points.
- Status: encoded by PO-3.

I-6. Public compatibility must be preserved.

- Source: Matplotlib public API shape and benchmark task.
- Evidence: the task asks for a minimal non-test source fix; no public API
  change is requested.
- Obligation: no changed public signature, return shape, artist type, or
  caller protocol.
- Status: encoded by PO-5.

## Domain

D-1. Finite paths and finite numeric vertices.

The proof domain is finite `Path` geometry with finite 2D numeric vertices, as
produced by `Axes.hist` step mode and ordinary patch paths.

D-2. Data-coordinate patch limit updates.

The main obligation is for patches whose transform contributes to
`transData`, because `_update_patch_limits` returns without updating limits
when neither axis is data-related.

D-3. Step histograms.

For `histtype="step"`, the path is an unfilled straight-line outline whose
maximum density occurs at one of the original path vertices. For horizontal
orientation, the same obligation applies after x/y swapping.

D-4. Partial correctness.

The proof is partial correctness: if `_update_patch_limits` reaches
`update_datalim`, then the points supplied to `update_datalim` include the
required unsimplified geometry. Termination and performance are not separately
proved.

## Formal Spec English

FS-1. Unsimplified iterator coverage.

For any finite path `P`, `P.iter_bezier(simplify=False)` iterates Bezier
segments derived from the unsimplified path returned by `P.cleaned(...,
simplify=False, ...)`. For a straight-line path, every original line endpoint
is present in at least one yielded Bezier segment endpoint.

FS-2. Candidate point coverage.

`_update_patch_limits` constructs its limit candidate points by taking each
unsimplified Bezier segment, adding its endpoints, and adding any
axis-aligned interior extrema reported by `axis_aligned_extrema()`.

FS-3. Step histogram limit coverage.

For a step histogram polygon, every bin-edge/top vertex of the outline is a
line endpoint. Therefore the candidate points passed to `update_datalim`
include the maximum histogram density and the x extent of the outline.

FS-4. No simplification-derived clipping.

Because simplification is disabled on the limit-calculation iterator, the
candidate point set cannot shrink to the smaller subset shown in the public
hint. Autoscaling is based on the full data geometry rather than the
appearance-simplified geometry.

FS-5. Frame conditions.

The V1 fix does not change the zero-size Rectangle skip, transform branch
tests, x/y axis update flags, call to `trf_to_data.transform`, or
`update_datalim` behavior.

## Spec Audit

- FS-1 vs I-4: pass. Public evidence specifically identifies default
  segment iteration/simplification as the bad limit input; disabling
  simplification is exactly the required precondition for the iterator.
- FS-2 vs I-5: pass. The formalized candidate point set keeps the existing
  Bezier extrema behavior.
- FS-3 vs I-1/I-2/I-3: pass. Step histograms are straight-line outlines, so
  their maxima are original vertices and are covered by FS-1 and FS-2.
- FS-4 vs I-4: pass. It directly excludes the public hint's failure mode.
- FS-5 vs I-6: pass. The edited call uses an existing keyword accepted by
  `Path.iter_bezier(**kwargs)` and forwarded to `Path.iter_segments`; no
  public protocol changes.

No spec-audit failure blocks keeping V1.

## Public Compatibility Audit

- Changed public symbol: none.
- Changed method signature: none.
- Changed call protocol: one internal call now passes `simplify=False` to
  `Path.iter_bezier`, whose signature is `iter_bezier(self, **kwargs)` and
  whose documented behavior is forwarding keyword arguments to
  `iter_segments`.
- Public callsites/subclasses: no public caller needs to change because this
  is an internal call inside `_update_patch_limits`.
- Producer/consumer shape: unchanged. `_update_patch_limits` still builds an
  array-like point set and passes it through the same transform and
  `update_datalim` path.

Compatibility status: pass.

## Formal Core Files

The constructed formal core is included in:

- `fvk/mini-python.k`
- `fvk/patch-limits-spec.k`

These files are intentionally small abstractions of the relevant Python and
Matplotlib path-limit operations, not a full Python or Matplotlib semantics.
They preserve the observable under verification: whether the point set used
for data limits contains every original straight-line step vertex.

## Machine-Check Commands

These commands were not run in this session:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/patch-limits-spec.k
kprove fvk/patch-limits-spec.k
```

Expected result: `kprove` discharges the claims to `#Top`. Until that is run,
the proof is constructed, not machine-checked.
