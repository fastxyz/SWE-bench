# FVK Findings

Status: constructed from public intent and static source inspection; not
machine-checked.

## F1 - Reported Bug: `Figure.subfigures` Spacing Was Ignored

Input:

```python
plt.figure().subfigures(2, 2, wspace=0.2, hspace=0.2)
```

Observed in the pre-fix implementation: `_redo_transform_rel_fig` used only
width and height ratios, so all subfigure cells touched exactly as they did for
`wspace=0, hspace=0`.

Expected: horizontal and vertical gaps computed as fractions of the average
subfigure cell width and height.

Classification: code bug, fixed by V1 and retained in V2.

Proof obligations: PO1, PO2, PO3, PO4.

## F2 - V1 Compatibility Gap: Generic GridSpec Spacing Leaked Into Subfigures

Input shape:

```python
fig = plt.figure()
gs = fig.add_gridspec(1, 2, wspace=0.5)
fig.add_subfigure(gs[0])
```

Observed in V1 by static inspection: `_redo_transform_rel_fig` read
`gs.wspace` / `gs.hspace` directly, so explicit subplot spacing on an arbitrary
GridSpec became manual subfigure spacing.

Expected from public issue discussion: subfigure spacing should be controlled by
the `Figure.subfigures(..., wspace=..., hspace=...)` kwargs, while
`add_subfigure(gs[i])` keeps ignoring GridSpec subplot spacing unless a
subfigure-specific spacing source exists.

Classification: code bug / compatibility risk in V1. V2 fixes it by storing
`_subfigure_wspace` and `_subfigure_hspace` only on GridSpecs created by
`Figure.subfigures`, and by making `_redo_transform_rel_fig` read only those
private attributes.

Proof obligations: PO1, PO5, PO8.

## F3 - Default Spacing Must Stay Zero

Input:

```python
fig = plt.figure()
fig.subfigures(1, 2)
```

Expected: adjacent subfigures in the manual layout path. The public discussion
identifies applying rcParam/default subplot spacing to subfigures as undesirable
for existing use cases.

Classification: frame condition / compatibility requirement. V2 preserves it:
missing `_subfigure_*` values and `None` values both become `0.0`.

Proof obligations: PO2, PO5.

## F4 - Domain Assumption: Exotic Ratios and Spacing Are Outside This Proof

Input shape:

```python
fig.subfigures(1, 2, width_ratios=[1, -1])
fig.subfigures(1, 2, wspace=-2)
```

Observed: the audited code, like nearby GridSpec arithmetic, assumes positive
ratio sums and nonzero layout denominators.

Expected: ordinary layout inputs have positive ratio sums and denominators.
The issue does not require changing validation behavior for exotic negative or
zero-sum cases.

Classification: missing proof domain / residual risk, not a requested code
change.

Proof obligations: PO9.

## F5 - Constrained Layout Override Remains Separate

Input shape:

```python
fig = plt.figure(layout="constrained")
subfig = fig.subfigures(1, 2, wspace=0.2)[0]
# later, constrained layout calls _redo_transform_rel_fig(bbox=...)
```

Expected: when an explicit bbox is supplied by the layout engine, the manual
GridSpec arithmetic must not interfere.

Classification: frame condition. V2 leaves the `bbox is not None` branch as a
direct assignment.

Proof obligations: PO6, PO7.
