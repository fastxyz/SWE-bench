# Findings

Status: FVK audit of V1. No execution or machine checking was performed.

## F1: Resolved Code Bug - Raw `q` Multiplication

- Evidence: E1, E2, E3; PO1, PO2, PO3.
- Input: `Rational('0.5', '100')`.
- Legacy observed behavior: `1/100100`, explained by multiplying raw string `'100'` by `2`.
- Expected behavior: `1/200`, the quotient of `Rational('0.5')` and `Rational('100')`.
- V1 status: resolved. `qden` carries the denominator contribution from `p`, and `q` is converted before integer arithmetic uses `q.p` or `q.q`.

## F2: Ambiguity Resolved - Error vs Quotient Semantics

- Evidence: E2, E3, E4, E6; PO2, PO8.
- Public tension: one hint says the input should probably raise an error, but the later public hint gives quotient-preserving logic and a family test that requires successful construction.
- Decision: do not add an error for string denominators. The stronger public evidence and existing constructor behavior support quotient semantics for valid rational-like operands.

## F3: V1 Satisfies the Family Algebra

- Evidence: PO2.
- For any converted finite operands `PN/PD` and `QN/QD`, V1 sets `p = PN * QD` and `q = PD * QN` before downstream canonicalization.
- Status: no source change required after FVK.

## F4: Frame Conditions Preserved

- Evidence: PO4, PO5, PO6, PO7, PO8.
- The source change is before the existing zero, sign, gcd, and canonical-return branches and does not change public signatures or tests.
- Status: no additional compatibility fix required.

## F5: Verification Honesty Gap

- Evidence: FVK docs and task constraint.
- The K-style proof was constructed but not machine-checked because this session forbids running `kompile`, `kprove`, tests, or Python.
- Status: keep tests; do not claim machine-checked proof until the emitted commands are run in a real environment.
