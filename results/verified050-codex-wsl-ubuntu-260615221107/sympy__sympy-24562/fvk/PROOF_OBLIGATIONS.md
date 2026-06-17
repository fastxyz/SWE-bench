# Proof Obligations

Status: constructed obligations; not machine-checked.

## PO1: No Raw Denominator Multiplication

After `p` is converted by `Rational(p)`, the raw object `q` must not be multiplied by `p.q`. This blocks Python string repetition and other raw-object multiplication effects.

V1 evidence: `qden = p.q` stores the integer denominator contribution; raw `q` is left untouched until `q = Rational(q)`.

## PO2: Finite Quotient Algebra

For converted finite values:

```text
Rational(p) = PN/PD, PD > 0
Rational(q) = QN/QD, QD > 0, QN != 0
```

the normalization block must produce the pre-canonical pair:

```text
p = PN * QD
q = PD * QN
```

This represents `(PN/PD) / (QN/QD)`.

## PO3: Reported Concrete Case

For `p = '0.5'` and `q = '100'`, conversion gives `PN=1`, `PD=2`, `QN=100`, `QD=1`. PO2 requires `p=1`, `q=200`, so the canonical result is `1/200`, not `1/100100`.

## PO4: Zero Denominator Frame

If `QN == 0`, the existing zero-denominator branch must still run after normalization:

- nonzero numerator -> `S.ComplexInfinity`;
- zero numerator -> `ValueError` if `_errdict["divide"]` is true, otherwise `S.NaN`.

## PO5: Sign Normalization Frame

If `PD * QN < 0`, the existing `if q < 0` branch must move the sign to the numerator. If `PD * QN > 0`, it must leave the sign unchanged.

## PO6: GCD and Canonical Return Frame

When `gcd` is falsey, the existing `igcd(abs(p), q)` reduction must reduce the pre-canonical pair. When `gcd=1`, common divisors must be preserved except for sign normalization. The existing `Integer` and `S.Half` singleton returns must remain downstream and unchanged.

## PO7: Invalid Input Frame

If `Rational(p)` or `Rational(q)` cannot convert the operand to a finite rational in this path, the constructor must continue to raise the existing error rather than silently manufacturing a value.

## PO8: Public Compatibility

The fix must not change the public `Rational.__new__` signature, add new dispatch requirements, alter test files, or require callsite updates.
