# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no public-intent-backed source defect
that requires a V2 code edit.

## Trace From Findings and Proof Obligations

F-001 identifies the original `cla()` bug: axes-owned children were removed
from `_children` without clearing stale `.axes` and `.figure` references. PO-1
proves the detachment helper's postcondition, and PO-2 proves that
`_AxesBase.__clear()` applies it to the relevant old axes-owned artists. This
justifies keeping the V1 edits in `repo/lib/matplotlib/artist.py` and
`repo/lib/matplotlib/axes/_base.py` unchanged.

F-002 identifies the analogous `clf()` path for figure-level artists and axes
removed during figure clearing. PO-3 proves that `FigureBase.clear()` now
applies the same detachment helper to old subfigures, axes, and figure-level
artist lists. This justifies keeping the V1 edits in
`repo/lib/matplotlib/figure.py` unchanged.

F-003 records the main scope decision: axis and spine objects are reset in
place by `Axes.__clear()` and are not deparented. PO-4 proves V1 does not pass
those retained objects through the detachment helper. This is why I did not
broaden the patch to every object returned by `Axes.get_children()`.

PO-5 shows that V1 did not change public method signatures or virtual dispatch
shape for `clear`, `cla`, or `clf`. No compatibility edit was needed.

F-004 and PO-6 record the verification boundary. I created constructed FVK
artifacts and command lines, but I did not run tests, Python, `kompile`, or
`kprove`, and I do not recommend deleting tests based on this run.

## Artifacts Produced

Required artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional K-core artifacts referenced by the proof:

- `fvk/mini-matplotlib-clear.k`
- `fvk/matplotlib-clear-spec.k`

## Source Changes During FVK

No source files under `repo/` were changed during the FVK phase. The only new
files are FVK artifacts and this report.
