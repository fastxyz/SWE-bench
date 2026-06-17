# Public Evidence Ledger

## E1: Reported Failure

- Source: `benchmark/PROBLEM.md`
- Evidence: `Rational('0.5', '100')` returns `1/100100`; `Rational(0.5, 100)` returns `1/200`; `1/200` is called the true value.
- Obligation: The string denominator must not be multiplied as a raw Python string; the quotient for the reported input is `1/200`.
- Status: Encoded by PO1, PO2, PO3 and the `REPORTED-CASE` claim.

## E2: Expected Construction Alternatives

- Source: public hints in `benchmark/PROBLEM.md`
- Evidence: `Rational('0.5/100')` and `Rational('0.5') / Rational('100')` both produce `1/200`.
- Obligation: The two-argument form should represent rational division of the separately converted arguments.
- Status: Encoded by PO2 and the `RATIONAL-QUOTIENT` claim.

## E3: Suggested Logic

- Source: public hints in `benchmark/PROBLEM.md`
- Evidence: The suggested logic stores a denominator accumulator, converts `p`, then converts `q`, then sets `q = Q`.
- Obligation: Accumulate denominator contributions using integer numerator/denominator fields after conversion; do not mutate raw `q`.
- Status: Encoded by PO1 and implemented by V1's `qden`.

## E4: Suggested Family Test

- Source: public hints in `benchmark/PROBLEM.md`
- Evidence: For `p` and `q` in `('1.5', 1.5, 2)`, compare `Rational(p, q).as_numer_denom()` to `Rational('%s/%s' % (p, q)).as_numer_denom()`.
- Obligation: The behavior is a family property over valid rational-like operands, not a one-point patch.
- Status: Encoded by PO2 and the adequacy audit.

## E5: Constructor Docstring

- Source: `repo/sympy/core/numbers.py`
- Evidence: "Rational is unprejudiced in accepting input"; string literals can represent exact rationals; invalid non-literal rational input raises `TypeError`.
- Obligation: Keep broad accepted input behavior while preserving invalid-input errors.
- Status: Encoded by PO7.

## E6: Public Tests

- Source: `repo/sympy/core/tests/test_numbers.py`
- Evidence: Existing public tests accept `Rational(1.0, 3)`, `Rational(1, 3.0)`, `Rational(S.Half, Rational(1, 3))`, zero denominators, and `gcd=1`.
- Obligation: Preserve two-argument conversion, zero denominator behavior, and low-level gcd behavior.
- Status: Encoded by PO4, PO5, PO6, PO8.
