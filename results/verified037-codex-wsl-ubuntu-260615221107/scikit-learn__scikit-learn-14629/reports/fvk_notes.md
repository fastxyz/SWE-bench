# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found no source-code problem requiring a V2
edit.

## Decisions Traced To Findings And Proof Obligations

1. Keep `MultiOutputClassifier.fit` override unchanged.

   Trace: F-1, PO-1, PO-2, PO-3.

   Reason: the override delegates to the existing shared fit implementation,
   then sets `self.classes_` from `self.estimators_` in the same order that
   `predict_proba` later uses. This directly discharges the missing-attribute
   failure reported by the issue.

2. Keep `MultiOutputClassifier.partial_fit` override unchanged.

   Trace: F-2, PO-4, PO-5.

   Reason: the public hint says fitted classifiers should store `classes_`.
   Successful incremental fitting is a fitted classifier state, and the override
   preserves delegated availability and the existing public signature.

3. Do not edit `repo/sklearn/model_selection/_validation.py`.

   Trace: F-3, PO-3, PO-7.

   Reason: `_fit_and_predict` already has the right generic consumer contract:
   list-valued predictions use `estimator.classes_[i_label]`. V1 repairs the
   producer metadata on `MultiOutputClassifier`, avoiding a special case in
   cross-validation.

4. Do not add fallback handling for wrapped classifiers that lack `classes_`
   after fitting.

   Trace: F-4, PO-6.

   Reason: public evidence states that classifiers should store `classes_` when
   fitted. Supporting classifier-like estimators that violate that contract is
   outside the issue's intended domain.

5. Do not change `MultiOutputRegressor`, probability computation, or
   `predict_proba` error behavior.

   Trace: F-5, PO-7.

   Reason: the issue concerns classifier fitted metadata. The existing
   `predict_proba` `ValueError` for non-probabilistic base estimators and
   regressor behavior are frame conditions.

6. Do not claim machine-checked verification or remove tests.

   Trace: F-6 and all proof obligations' status lines.

   Reason: the benchmark forbids running K, Python, or tests. The proof is
   constructed only; the emitted K commands must be run later before treating it
   as machine-checked.

## Artifact Changes

Added the requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Added supporting FVK adequacy and formal-core artifacts required by the FVK
documentation:

- `fvk/mini-python.k`
- `fvk/multioutput-classes-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
