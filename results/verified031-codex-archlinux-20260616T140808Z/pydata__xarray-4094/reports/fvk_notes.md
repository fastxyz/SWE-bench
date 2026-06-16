# FVK Notes

Status: FVK audit completed with constructed, not machine-checked artifacts.
No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Decisions

1. Kept the core V1 coordinate-drop idea.
   - Trace: `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO3/PO7.
   - Reason: the reported `MergeError` comes from consumed stacked coordinate
     metadata being merged across output variables. Dropping `dim` and
     `variable_dim` before `Dataset(data_dict)` directly removes that conflict
     source without weakening merge compatibility globally.

2. Replaced V1's unrestricted `.squeeze(drop=True)`.
   - Trace: `fvk/FINDINGS.md` F2 and `fvk/PROOF_OBLIGATIONS.md` PO4/PO5/PO6.
   - Reason: FVK's intent pass identified sample dimensions as frame
     conditions from the `to_stacked_array` contract. V1 would also squeeze a
     legitimate length-one sample dimension, so V2 now computes
     `dims_to_squeeze` explicitly and squeezes only singleton consumed stacked
     metadata that is not carrying real remaining levels, or single-null
     missing-level placeholders.

3. Preserved existing mixed-dimensional behavior.
   - Trace: `fvk/FINDINGS.md` F3 and `fvk/PROOF_OBLIGATIONS.md` PO5/PO6/PO8.
   - Reason: variables that actually own a remaining stacked level must keep
     it, while variables with a null placeholder should lose that placeholder.
     The null-sentinel check is the narrow distinction needed for both cases.

4. Added a defensive duplicate-name guard in the squeeze list.
   - Trace: `fvk/FINDINGS.md` F4 and `fvk/PROOF_OBLIGATIONS.md` PO8.
   - Reason: unusual MultiIndex names should not make the repair pass duplicate
     dimensions to `squeeze`. The guard is behavior-preserving for normal
     roundtrips and avoids a new compatibility edge case.

5. Did not edit tests or broaden the implementation beyond the audited method
   body.
   - Trace: `fvk/PROOF_OBLIGATIONS.md` PO9 and
     `fvk/ITERATION_GUIDANCE.md`.
   - Reason: the task forbids modifying tests and executing code. The FVK
     artifacts identify future validation cases, but no test-removal or
     machine-verified claim is made.

## Result

V1 did not stand unchanged. V2 keeps the merge-conflict repair while improving
dimension preservation according to the FVK intent/spec audit.
