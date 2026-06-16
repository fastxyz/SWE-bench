# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit confirms that the fix belongs in
`GeoEncodingUtils.createSubBoxes`, where the component predicate grid converts double query bounds
back to encoded integer cells.

## Decisions Traced to FVK Artifacts

1. Keep the conservative helper approach.

   Trace: `fvk/FINDINGS.md` F-1 and `fvk/PROOF_OBLIGATIONS.md` PO-1, PO-2, PO-4.

   Reason: the public issue identifies a component-predicate false negative for a narrow polygon
   near the maximum encoded latitude. PO-2 states the required general property: every encoded
   coordinate whose decoded value is within the query interval must remain inside the grid bounds.
   V1's lower helpers repair upward raw-ceil drift, and its upper helpers repair downward raw-floor
   drift.

2. Keep the change in the shared predicate instead of changing only `LatLonDocValuesQuery`.

   Trace: `fvk/FINDINGS.md` F-5 and `fvk/PROOF_OBLIGATIONS.md` PO-1, PO-2.

   Reason: the alternative of decoding every doc-values point and calling `component2D.contains`
   directly would address the symptom in one caller, but would leave the shared
   `Component2DPredicate` capable of rejecting valid encoded boundary cells. The issue text points
   to the predicate, so the shared fix is the stronger and better localized repair.

3. Do not add further source edits.

   Trace: `fvk/FINDINGS.md` F-2, F-3 and `fvk/PROOF_OBLIGATIONS.md` PO-3, PO-6.

   Reason: F-2 and PO-3 show that conservative expansion preserves exact filtering: crossing cells
   still call `tree.contains`, and inside cells rely on the existing `Component2D.relate` contract.
   F-3 and PO-6 show the patch is private and source-scoped, with no public API, encoding format,
   relation semantics, or test-file change.

4. Record but do not execute formal commands.

   Trace: `fvk/PROOF.md` "Machine-Check Commands Not Run" and
   `fvk/PROOF_OBLIGATIONS.md` "Proof Capability Boundaries".

   Reason: the task forbids tests, Python, and K tooling. The artifacts therefore contain the
   constructed proof, expected `kompile`/`kprove` commands, and the explicit caveat that the proof
   is not machine-checked.

## Residual Assumption

The proof relies on the existing `Component2D.relate` contract being sound with respect to
`Component2D.contains`. This is recorded in `fvk/FINDINGS.md` F-4 and
`fvk/PROOF_OBLIGATIONS.md` PO-3. It is not a new source change because the public issue localizes
the failure to the component predicate grid rejecting encoded boundary cells before exact checks.

## Files Added

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-java-geo.k`
- `fvk/geoencodingutils-spec.k`
- `reports/fvk_notes.md`

No production source files were changed during the FVK pass.
