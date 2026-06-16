# FVK Notes

## Decisions

1. Kept V1's `baseApproximation.nextDoc()` initialization.

   This is justified by `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` O2-O3. The public issue identifies the original `baseIterator.nextDoc()` as a premature two-phase confirmation, and the proof obligation requires initialization to position only a candidate.

2. Kept V1's explicit base confirmation in `doDrillDownAdvanceScoring` and `doUnionScoring`.

   This is justified by F2 and O4-O5. Once initialization advances only the approximation, the chunked branches must not consume `baseIterator.docID()` as though it were a confirmed match. They now advance `baseApproximation` and check `baseTwoPhase.matches()` before scoring.

3. Added a V2 fix for the second drill-down dimension in `doDrillDownAdvanceScoring`.

   This is justified by F3 and O6-O7. The V1 condition treated `acceptDocs == null` as enough to accept `dims[1]` without evaluating `dc.twoPhase.matches()`. The revised condition makes live-doc acceptance and two-phase confirmation independent:

   ```java
   if ((acceptDocs == null || acceptDocs.get(docID))
       && (dc.twoPhase == null || dc.twoPhase.matches())) {
   ```

4. Made no public API changes.

   This is justified by O8 and the compatibility audit in `fvk/SPEC.md`. The fix is internal to `DrillSidewaysScorer` and preserves the existing collector interfaces, scoring strategy selection, chunking, and hit/near-miss accounting.

## Verification Caveat

The FVK proof is constructed, not machine-checked, because this task forbids running K tooling, tests, Python, or project code. This limitation is recorded as F4 and O8. It does not block the V2 source edit because the edit follows directly from public intent, Java boolean precedence, and the `TwoPhaseIterator` contract.
