# Formal Spec, Paraphrased in English

Status: constructed, not machine-checked.

## Claim `MOD-GCD-POLYERR`

For any symbolic dividend `P` and divisor `Q`, if `Q` is not a zero divisor, no
earlier direct `Mod` evaluation applies, and the optional polynomial `gcd`
extraction raises `PolynomialError`, then `Mod.eval` reaches a symbolic modulo
state equivalent to using `G = 1` with the original `P` and `Q`. It does not
reach a `PolynomialError` result.

## Claim `MOD-GCD-OK`

For any symbolic dividend `P`, divisor `Q`, and common factor `G`, if `Q` is not
a zero divisor, no earlier direct `Mod` evaluation applies, and `gcd(P, Q)`
succeeds with `G`, then `Mod.eval` continues with that `G` on the original
successful path.

## Claim `MOD-ZERO-DIVISOR`

For any symbolic dividend `P`, divisor `Q`, and `gcd` outcome, if `Q` is a zero
divisor, `Mod.eval` reaches the modulo-by-zero error before any `gcd` extraction
can run.

## Frame Conditions

The formal claims do not change `Mod`'s public call shape, do not define
standalone `gcd(Piecewise, ...)`, and do not define global assumptions-cache
rollback behavior.

