# Intent Spec

Status: constructed from public evidence only. No tests, Python, K tooling, hidden results, or internet access were used.

## Target

The audited unit is the two-argument normalization path in `Rational.__new__` in `repo/sympy/core/numbers.py`.

## Intent Obligations

I1. `Rational('0.5', '100')` must not evaluate by repeating the raw string denominator. The issue reports `1/100100` as the bug and identifies `1/200` as the true value.

I2. The two-argument constructor must be consistent with converting each argument to a rational and dividing: `Rational('0.5') / Rational('100') == 1/200`.

I3. For valid simple rational-like inputs, `Rational(p, q)` should match the rational value represented by `Rational('%s/%s' % (p, q))`, as stated in the public suggested test family.

I4. Invalid inputs that do not reduce to a literal rational remain errors. The constructor docstring states that non-rational input such as `pi` raises `TypeError`.

I5. Existing public constructor behavior for zero denominator, negative denominator normalization, automatic gcd reduction, and the `gcd=1` low-level escape hatch must be preserved unless it conflicts with I1-I3. The public tests around `Rational(1, 0)`, `Rational(-1, 0)`, and `Rational(2, 4, gcd=1)` support this frame condition.

## Domain

The primary proof domain is two-argument construction where both `Rational(p)` and `Rational(q)` are finite rational values. Write:

- `Rational(p) = PN/PD`, with `PD > 0`.
- `Rational(q) = QN/QD`, with `QD > 0`.

For the finite quotient claim, `QN != 0`. Zero denominator behavior is a separate frame obligation because SymPy intentionally returns complex infinity or raises/returns NaN for `0/0` depending on `_errdict["divide"]`.

## Rejected Interpretation

The public hints include "This should probably raise an error." I reject that as the final spec because the same public hint then identifies the string multiplication as the flaw, gives replacement logic that converts both operands, and gives a family test requiring the two-argument form to agree with rational division. Existing public tests also accept non-integer operands in either position.
