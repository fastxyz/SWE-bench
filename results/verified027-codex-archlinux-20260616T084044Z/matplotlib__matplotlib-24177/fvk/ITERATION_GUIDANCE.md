# FVK ITERATION GUIDANCE: matplotlib__matplotlib-24177

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

## Rationale

- F-001 identifies the pre-V1 bug: default path simplification could remove
  step vertices required for data limits.
- PO-2 shows V1 disables that simplification at the exact iterator used by
  `_update_patch_limits`.
- PO-3 shows V1 preserves the Bezier-extrema point construction.
- PO-4 shows the reported histogram density maximum is one of the original
  step polygon vertices, so PO-2 and PO-3 imply it reaches `update_datalim`.
- F-005 and PO-5 show no public compatibility blocker.

## Recommended Code Action

No source change beyond V1.

The one-line change remains:

```python
for curve, code in p.iter_bezier(simplify=False):
```

## Recommended Tests For A Later Executable Environment

Do not add or edit tests in this benchmark session. In a normal development
environment, add coverage for:

- `Axes.hist(..., density=True, histtype="step")` with enough bins/vertices to
  trigger path simplification under default iteration;
- comparison of vertical step histogram `dataLim` y max against the histogram
  density maximum;
- the horizontal orientation analogue, checking the density axis after x/y
  swapping;
- a curve or PathPatch case confirming Bezier extrema behavior is not
  regressed.

## Tests To Keep

Keep existing tests until:

1. normal tests can be run; and
2. the constructed K proof is machine-checked with `kprove`.

No test removal is recommended in this session.

## Follow-Up Questions

No user clarification is needed for the reported issue. The only residual
boundary is proof scope: a full Matplotlib verification would need a richer
semantics for NumPy arrays, transforms, `Bbox`, and arbitrary patch subclasses.
