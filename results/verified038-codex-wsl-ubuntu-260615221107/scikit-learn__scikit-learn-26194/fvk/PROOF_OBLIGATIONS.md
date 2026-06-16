# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO-1: Intent Adequacy

The formal contract must express the public intent rather than legacy behavior:
`thresholds[0]` is artificial, represents no predicted positives, and is not an
observed probability threshold.

Evidence: SPEC I1-I6, E1-E5.

Status: discharged in SPEC A1-A3 and PROOF sections P1-P3.

## PO-2: Producer Shape

Given validated in-domain `roc_curve` inputs, after `_binary_clf_curve` and
optional `drop_intermediate`, the local arrays `fps`, `tps`, and `thresholds`
have equal non-zero length and `thresholds` contains observed finite score
values.

Evidence: implementation flow in `_binary_clf_curve` and `roc_curve`; SPEC E8.

Status: assumed as a producer obligation for the sentinel proof. Not fully
machine-modeled in this FVK pass; see FINDINGS F-4.

## PO-3: No-Prediction Sentinel

For every finite validated input score `s`, the first artificial threshold
must make `s >= threshold[0]` false. Therefore the prepended threshold must be
strictly above all finite scores, or be an explicit sentinel with that
comparison semantics.

Evidence: SPEC E3, E5, E7.

Status: discharged by `np.inf`; represented by claim C3 in
`fvk/roc-curve-spec.k`.

## PO-4: Probability Boundedness of Finite Thresholds

If every observed threshold produced from probability estimates is finite and
in `[0, 1]`, then after prepending the artificial first threshold every finite
returned threshold is still in `[0, 1]`. No finite threshold above 1 is
fabricated.

Evidence: SPEC E1, E2, E4.

Status: discharged by `np.inf`; represented by claim C2 in
`fvk/roc-curve-spec.k`.

## PO-5: Reject Clipping

The suggested clipping workaround must not be accepted unless it preserves
PO-3. With an observed score exactly `1`, a clipped first threshold equal to
`1` violates PO-3 because `score >= 1` is true for that sample.

Evidence: SPEC E3, E5.

Status: discharged as a counterexample in PROOF P4 and
`fvk/roc-curve-spec.k`.

## PO-6: Public API and Documentation Compatibility

The fix must keep the public `roc_curve` signature and return shapes unchanged,
and public documentation must not keep displaying the old finite sentinel as
the expected output.

Evidence: SPEC I5, E6, CA1-CA5.

Status: discharged. Signature and shape are unchanged; docs/examples were
updated. Exact public tests expecting `2.0` are SUSPECT legacy evidence and
were not modified due task constraints.

## PO-7: Honesty Gate

The FVK result must clearly state that it is constructed, not machine-checked,
and must not claim full Python/NumPy verification or recommend deleting tests
unconditionally.

Evidence: FVK `verify.md` honesty gate.

Status: discharged in PROOF and ITERATION_GUIDANCE.
