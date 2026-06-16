# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision

V1 stands unchanged. The FVK audit found no additional production-code edit
justified by the public intent and proof obligations.

Trace:

- FINDINGS F-1 is resolved by `np.inf`.
- FINDINGS F-3 rejects the only issue-suggested alternative, clipping to 1.
- PROOF_OBLIGATIONS PO-3 and PO-4 are discharged by the V1 sentinel.
- PROOF_OBLIGATIONS PO-6 is discharged by unchanged API shape and updated
  documentation examples.

## Do Not Change in This Pass

- Do not clip the first threshold to 1. It violates PO-5 when an observed score
  is exactly 1.
- Do not restore `thresholds[0] + 1`. It reintroduces FINDINGS F-1.
- Do not edit tests in this benchmark session. Tests are fixed and hidden by
  task constraint; public exact tests are recorded only as SUSPECT legacy
  evidence in F-2.

## Recommended Future Work

- In a normal development environment, update public exact-threshold tests that
  expect `[2.0, ...]` to expect `[np.inf, ...]`.
- Run the emitted FVK commands after installing K, then run the ordinary
  scikit-learn test suite.
- If a broader formal proof is required, replace the abstract `mini-roc.k`
  model with a larger mini-Python/NumPy model that covers `_binary_clf_curve`,
  `drop_intermediate`, floating-point arrays, and warning behavior. This is the
  path for closing FINDINGS F-4.

## Notes for the Next Code Generator

The core invariant to preserve is: the first ROC threshold is an explicit
sentinel for "no predicted positives"; all finite thresholds remain observed
score thresholds. Any future refactor of `roc_curve` should keep that
distinction visible in code and docs.
