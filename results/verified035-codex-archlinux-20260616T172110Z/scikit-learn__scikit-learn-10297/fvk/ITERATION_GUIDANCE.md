# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No source edit beyond V1 is justified by the FVK audit. The public intent is the
constructor flag and the fitted `cv_values_` attribute; V1 satisfies that by
exposing `store_cv_values`, passing it to `_BaseRidgeCV`, and reusing the
existing storage path.

## Trace to Findings and Obligations

- Keep the V1 constructor change: supported by F-001 and PO-001.
- Keep `store_cv_values` appended after `class_weight`: supported by F-002 and
  PO-004.
- Do not add classifier-specific cv-values code: supported by F-003 and PO-002.
- Do not change numerical ridge code: supported by F-004 and PO-005.
- Do not edit tests in this task: the prompt forbids test-file edits, and the
  proof is constructed rather than machine-checked.

## Recommended Future Tests

These are recommendations only; no tests were edited.

- Add a classifier-specific regression test that fits
  `RidgeClassifierCV(store_cv_values=True)` with `cv=None` and checks
  `cv_values_` exists.
- Add or preserve a test that `RidgeClassifierCV(cv=..., store_cv_values=True)`
  raises the documented incompatibility `ValueError`.
- Add or preserve an estimator API test that `get_params()` includes
  `store_cv_values`.

## Do Not Remove

- Do not remove existing `RidgeCV` storage tests; they do not cover
  `RidgeClassifierCV`.
- Do not remove numerical ridge or classifier integration tests; this proof does
  not establish numerical correctness or termination.
