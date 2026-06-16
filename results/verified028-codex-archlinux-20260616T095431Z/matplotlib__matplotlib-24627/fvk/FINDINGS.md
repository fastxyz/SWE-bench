# FVK Findings

Status: constructed from public intent and source inspection; not
machine-checked.

## F-001 - Resolved: `Axes.cla()` Left Axes-Owned Artists Parent-Bound

Evidence: `SPEC.md` E-1, E-2, E-3; `PROOF_OBLIGATIONS.md` PO-1 and PO-2.

Input / scenario:

```python
f, a = plt.subplots()
l, = a.plot([1, 2])
a.cla()
```

Observed before V1 from the issue: `l.axes` still reported the old `Axes`.
Expected by public intent: `l.axes is None` and, per the issue title,
`l.figure is None`.

Root cause: `_AxesBase.__clear()` replaced `_children` with a new list without
running the parent-detachment bookkeeping that `Artist.remove()` performs for a
single artist.

V1 status: resolved. `_AxesBase.__clear()` snapshots old `_children` and applies
`_remove_artist_from_parent()` to each artist after dropping the list.

## F-002 - Resolved: `Figure.clf()` Dropped Figure-Owned Artists Without Detach

Evidence: `SPEC.md` E-1, E-5; `PROOF_OBLIGATIONS.md` PO-1 and PO-3.

Input / scenario:

```python
f = plt.figure()
t = f.text(0.5, 0.5, "label")
f.clf()
```

Observed before V1 by source inspection: `FigureBase.clear()` replaced
`texts` and other figure-level artist lists without clearing those artists'
`.figure` references.

Expected by public intent: a pre-existing artist deparented by `clf()` must no
longer report the old figure.

V1 status: resolved. `FigureBase.clear()` snapshots the figure-level artist
lists and applies `_remove_artist_from_parent()` before replacing those lists.

## F-003 - Confirmed Non-Bug: Retained Axis and Spine Objects Stay Parent-Bound

Evidence: `SPEC.md` E-4; `PROOF_OBLIGATIONS.md` PO-2.

Input / scenario:

```python
f, a = plt.subplots()
xaxis = a.xaxis
spine = a.spines["left"]
a.cla()
```

Observed by source inspection: axis and spine objects are cleared in place and
remain reachable from the same axes after `cla()`.

Expected by public intent: only deparented artists must have `.axes` and
`.figure` unset. Axis and spine objects are not deparented by `cla()`; they are
retained structural components.

V1 status: no source change required.

## F-004 - Residual Verification Boundary: Constructed, Not Machine-Checked

Evidence: `PROOF.md`; `PROOF_OBLIGATIONS.md` PO-6.

Input / scenario: any in-domain `cla()` or `clf()` path covered by the spec.

Observed in this environment: no tests, Python execution, `kompile`, or
`kprove` may be run.

Expected by FVK honesty gate: proof and commands are written as constructed
artifacts, but they are not presented as machine-checked.

V1 status: no source change required. The code decision is based on static
intent/proof reasoning; test removal is not recommended.

## Summary Verdict

The FVK audit found the original issue mechanisms and V1 addresses them. It did
not surface a public-intent-backed defect requiring a V2 source change.
