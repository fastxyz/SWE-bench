# Formal Spec English

Status: paraphrase of the constructed K-style claims in `rational-normalization-spec.k`.

## RATIONAL-QUOTIENT

For every pair of already converted finite rational operands `PN/PD` and `QN/QD`, where `PD > 0`, `QD > 0`, and `QN != 0`, the two-argument normalization computes the pre-canonical numerator and denominator:

- numerator: `PN * QD`
- denominator: `PD * QN`

The later canonicalization step may normalize sign, reduce by gcd when automatic reduction is enabled, and return singleton objects such as `Integer` or `S.Half`, but the represented mathematical value is `(PN/PD) / (QN/QD)`.

## REPORTED-CASE

When the first argument converts to `1/2` and the second argument converts to `100/1`, normalization reaches the rational result `1/200`.

## ZERO-DENOMINATOR

When the converted second argument has numerator `0`, the existing zero denominator behavior is preserved: a nonzero numerator produces `S.ComplexInfinity`; `0/0` follows `_errdict["divide"]` by raising `ValueError` when enabled and otherwise returning `S.NaN`.

## NO-RAW-Q-MULTIPLY

The normalization never applies arithmetic to the raw second argument after the first argument is converted. The only multiplication involving the second operand occurs after `Rational(q)` has produced integer fields `q.p` and `q.q`.

## FRAME

Invalid input handling, sign normalization, gcd reduction, `gcd=1`, `Integer` return, and `S.Half` return are frame behavior from the existing constructor and are not weakened by the V1 patch.
