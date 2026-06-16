# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found no source-code issue requiring a V2
edit.

## Trace to Findings and Obligations

F1 identifies the original defect as mixed scorer target representations. The
relevant obligations are PO-C1, PO-S1, and PO-S2: classifier targets must be
decoded through `classes_`, and both training and validation scorer calls must
receive the decoded representation. V1 satisfies these obligations via
`HistGradientBoostingClassifier._get_y_for_scorer` and the two helper calls in
`_check_early_stopping_scorer`, so no change was made.

F2 checks whether V1 missed another scorer callsite. PO-S1, PO-S2, and PO-S3
cover the initial scorer call, per-iteration scorer calls, validation scoring,
and train-only scoring because all of those paths share
`_check_early_stopping_scorer`. This supports keeping V1 unchanged.

F3 checks for unintended behavior changes. PO-B1 confirms base/regression
targets pass through unchanged, and PO-L1 confirms `scoring='loss'` remains on
the internal encoded target path. This supports the decision not to decode
targets earlier in `fit` or in the loss path.

F4 is a test gap, not a source defect: public tests do not cover string labels
on the early-stopping scorer path. The task forbids modifying tests, so no test
files were changed. `ITERATION_GUIDANCE.md` records the future tests to add.

F5 records that the proof is constructed, not machine-checked. PO-V1 keeps the
K commands as future verification steps and prevents claiming machine-checked
confidence or recommending test deletion now.

## Compatibility Decision

`PUBLIC_COMPATIBILITY_AUDIT.md` entries C1-C3 show that `_get_y_for_scorer` is a
private helper with only internal callsites in `gradient_boosting.py`. No public
API, estimator constructor, scorer signature, prediction output, or score array
shape changed. This supports keeping the V1 hook-based design rather than
replacing it with a broader public or signature-level change.

## Execution Constraint

No tests, Python, or K tooling were run. All conclusions are from static source
inspection, public intent evidence, and constructed FVK proof obligations.
