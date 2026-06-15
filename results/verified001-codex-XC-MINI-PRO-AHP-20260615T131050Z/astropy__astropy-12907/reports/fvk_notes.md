## Decision

V1 stands unchanged. The FVK audit found the same root cause as the baseline and
confirmed that the V1 source edit discharges the relevant proof obligation.

## Trace to findings and proof obligations

FVK-F1 identifies the bug: a nested right-hand coordinate matrix was overwritten
with ones. That is exactly the violation of PO-3, right block preservation.

FVK-F2 confirms V1's assignment
`cright[-right.shape[0]:, -right.shape[1]:] = right` implements PO-3 by copying
the nested matrix into the lower-right block. This also supports PO-5, because
right-hand nested `&` matrices keep their internal zero entries after placement.

FVK-F3 limits the proof claim to the matrix `&` path that caused the issue.
Because this pass did not derive a bug in `|`, arithmetic operators, or public
API compatibility, no additional source edit is justified.

PO-1 through PO-4 specify the full block-matrix behavior needed for the reported
case. PO-6 confirms the repair does not change signatures, dispatch, return
types, or public APIs.

## Artifacts and execution status

The FVK artifacts are in `fvk/`. The `.k` proof core is included as
`fvk/mini-python-separability.k` and `fvk/separability-spec.k`, with exact
commands in `fvk/PROOF.md`.

No tests, Python imports, or K framework commands were run, per the task
constraint. The proof is constructed, not machine-checked.
