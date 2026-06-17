# FVK Notes

## Decision

V1 is confirmed unchanged.

## Trace to Findings and Proof Obligations

`fvk/FINDINGS.md` F1 identifies the original defect as raw multiplication of `q` after converting `p`. PO1 requires that raw multiplication to be removed, and PO2 requires quotient algebra over the converted rational fields. The V1 source satisfies both by storing `p.q` in `qden`, leaving raw `q` untouched, then using `q.p` and `q.q` only after `q = Rational(q)`.

F1 and PO3 cover the concrete issue input. With `Rational('0.5') = 1/2` and `Rational('100') = 100/1`, V1 reaches the pair `(1, 200)`, so the legacy `(1, 100100)` result is unreachable.

F2 records the only public ambiguity: whether the two-argument string form should instead raise an error. I kept V1's successful quotient behavior because PO2 is supported by the public replacement logic and suggested family test, while PO8 requires avoiding unnecessary public API or compatibility changes.

F3 is the main reason no second source edit was made. It traces the family property to PO2: all finite converted operands normalize to `(PN * QD, PD * QN)`.

F4 traces the no-change decision for downstream behavior to PO4 through PO7. The V1 patch is before the existing zero-denominator, sign, gcd, invalid-input, `Integer`, and `S.Half` branches, so those frame obligations remain satisfied.

F5 explains the verification limit. The proof and K-style artifacts are constructed but not machine-checked because this session forbids running K tooling, Python, or tests.

## Files

Source files changed in this FVK phase: none.

Artifacts added under `fvk/`: required FVK summary files plus the adequacy documents and constructed K-style spec files.
