# FVK Notes

## Decision summary

The FVK audit confirms V1 stands unchanged. No additional source edit is
justified by the public intent, findings, or proof obligations.

## Decisions traced to FVK artifacts

1. Keep `store_cv_values=False` in `RidgeClassifierCV.__init__`.
   - Finding trace: `fvk/FINDINGS.md` F-001 identifies the pre-V1
     unexpected-keyword error as the reported bug and marks V1 resolved.
   - Proof trace: `fvk/PROOF_OBLIGATIONS.md` PO-001 requires the constructor to
     accept and store the new flag.

2. Keep the `super(...).__init__(..., store_cv_values=store_cv_values)`
   delegation.
   - Finding trace: F-003 says no classifier-specific `cv_values_`
     implementation is needed because `_BaseRidgeCV` already owns the storage
     path.
   - Proof trace: PO-002 proves the flag-propagation path through
     `_BaseRidgeCV.fit` to `_RidgeGCV` and back to `self.cv_values_`.

3. Keep `store_cv_values` appended after `class_weight`.
   - Finding trace: F-002 confirms this preserves existing constructor
     compatibility.
   - Proof trace: PO-004 covers scikit-learn estimator compatibility and the
     explicit-parameter/attribute requirement used by `get_params`.

4. Do not change `_BaseRidgeCV`, `_RidgeGCV`, or numerical ridge code.
   - Finding trace: F-003 confirms the existing base path satisfies the issue's
     storage requirement; F-004 marks numerical GCV correctness and termination
     outside this proof slice.
   - Proof trace: PO-005 rejects unjustified source expansion beyond the public
     constructor/storage intent.

5. Do not edit tests.
   - Finding trace: F-004 says the constructed proof does not subsume numerical
     or integration tests.
   - Proof trace: PO-002 is conditioned on existing in-domain fit behavior and
     PO-005 limits the repair scope. The task also explicitly forbids modifying
     test files.

## Execution constraints

No Python, test, `kompile`, `kast`, or `kprove` command was run. The proof in
`fvk/PROOF.md` is therefore constructed, not machine-checked, and records the
commands that would be used later.
