# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Rationale

F-001 and PO-001 show that the original defect is fixed by the V1 edit: `get_feature_names()` now materializes a valid constructor vocabulary before checking fittedness.

F-002 and PO-002 show that already-fitted or already-materialized vectorizers keep the previous return path.

F-003 and PO-003 show that unfitted vectorizers without a constructor vocabulary still raise `NotFittedError`, which preserves the public boundary behavior.

F-004 and PO-004 show that invalid constructor vocabularies still route through the existing validation errors instead of gaining a new unchecked path.

F-005 and PO-005 show that no public signature, caller protocol, subclass override, or return shape needs a compatibility repair.

## Rejected edits

No additional source edit is justified by the FVK findings.

Changing `_check_vocabulary()` globally was rejected because the issue-specific obligation is limited to `get_feature_names()` and a global helper change would affect `inverse_transform()` and other callers without public evidence.

Moving validation to `__init__` was rejected because the existing design validates constructor vocabularies lazily in `transform()` and `fit_transform()`, and the issue asks for `get_feature_names()` to behave in the same manner.

Adding tests was not performed because the task forbids modifying test files.

## Future verification

When an execution environment exists, run the commands recorded in `fvk/PROOF.md`, then run the relevant project tests. Until then, keep all tests and treat this proof as constructed, not machine-checked.

