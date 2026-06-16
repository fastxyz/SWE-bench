# Proof Obligations - sympy__sympy-17318

Status: constructed, not machine-checked.

## PO1 - `_sqrt_match` must not call `split_surds` on flat complex no-surd adds

Given an additive expression `p` whose addends have rational squares but not all
of those squares are positive, the `split_surds` fast path is disabled. If the
maximum square-root depth among addends is `0`, `_sqrt_match(p)` returns `[]`.

Evidence: I1, I2, I3.

Discharges findings: F1.

## PO2 - `split_surds` must be total on additive inputs with no square-root surds

Given an additive expression with no `Pow` term whose exponent is `S.Half`,
`split_surds(expr)` returns `(S.One, S.Zero, expr)`.

Evidence: I3, I4.

Discharges findings: F2 and F3.

## PO3 - `_split_gcd` must be safe on empty input and preserve non-empty behavior

For empty input, `_split_gcd()` returns `(S.One, [], [])`. For non-empty input,
it preserves the existing gcd-partition behavior.

Evidence: I3 and implementation compatibility search.

Discharges findings: F2 and F5.

## PO4 - `rad_rationalize` must stop when there is no square-root component

Given `den.is_Add` and `split_surds(den) == (g, a, b)` with `a == 0`,
`rad_rationalize(num, den)` returns `(num, den)` without a recursive call.

Evidence: I4.

Discharges findings: F3.

## PO5 - Valid square-root rationalization must still execute

Given `den = sqrt(2) + I`, `split_surds(den)` still identifies `sqrt(2)` as the
square-root component, and `rad_rationalize(1, den)` symbolically performs the
same conjugate step to `(sqrt(2) - I, 3)`.

Evidence: I5.

Discharges findings: F4.

## PO6 - Public compatibility must hold

Changed functions keep their signatures and return arities. Public callers of
`split_surds`, `rad_rationalize`, and `_split_gcd` remain compatible.

Evidence: source search of non-test callers.

Discharges findings: F5.

## PO7 - The repair must not rely on exception swallowing

The fix is implemented as branch guards and source-local handling of unsupported
inputs. No bare `except` is introduced.

Evidence: I6.

Discharges findings: F1, F2, and F3.
