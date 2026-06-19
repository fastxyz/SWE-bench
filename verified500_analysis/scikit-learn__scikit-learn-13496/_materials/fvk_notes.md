# FVK Notes

Status: constructed, not machine-checked.

## Decisions traced to FVK artifacts

1. Kept the V1 core fix: `IsolationForest.__init__` exposes
   `warm_start=False` and forwards it to `BaseBagging`.
   - Trace: `fvk/FINDINGS.md` F2, F3.
   - Proof obligations: `fvk/PROOF_OBLIGATIONS.md` PO1, PO2, PO3.

2. Changed the V1 parameter placement: moved `warm_start` from before `n_jobs`
   to after `verbose`.
   - Trace: `fvk/FINDINGS.md` F1.
   - Proof obligation: `fvk/PROOF_OBLIGATIONS.md` PO4.
   - Rationale: V1 enabled the keyword but shifted old positional calls. V2
     preserves old positional mapping and still enables the new keyword.

3. Kept the documentation change in the class docstring, with the requested
   RandomForest-style wording.
   - Trace: `fvk/FINDINGS.md` F2.
   - Proof obligation: `fvk/PROOF_OBLIGATIONS.md` PO5.

4. Did not add IsolationForest-specific warm-start fitting logic.
   - Trace: `fvk/FINDINGS.md` F3.
   - Proof obligation: `fvk/PROOF_OBLIGATIONS.md` PO2.
   - Rationale: public intent says the parent `BaseBagging` behavior already
     works; the missing piece was public constructor exposure.

5. Did not edit tests or run tests, Python, or K tooling.
   - Trace: `fvk/FINDINGS.md` residual proof limitation.
   - Proof obligation: `fvk/PROOF_OBLIGATIONS.md` PO6.
   - Rationale: the benchmark instructions explicitly forbid those actions.

## Result

The FVK audit improved V1 into V2 by preserving public positional
compatibility. The final source change remains targeted to
`repo/sklearn/ensemble/iforest.py`.
