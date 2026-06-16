# FVK Findings

Status: constructed, not machine-checked. Findings are from public intent,
static source inspection, and constructed proof reasoning only.

## F1: Reported coefficient case is resolved by V1

Input: `Mod(3*i, 2)` with `i` an integer symbol.

Observed before fix: the issue reports that it remained `Mod(3*i, 2)`.

Expected: `Mod(i, 2)`.

V1 status: resolved. The V1 branch applies because `cp = 3`, `cq = 2`, the
divisor tail is `S.One`, and the remaining dividend tail `i` is known integer.
Since `3 % 2 = 1`, reconstruction proceeds with dividend `i` and divisor `2`.

Related proof obligations: PO1, PO2.

## F2: Denominator corner case remains guarded

Input: `Mod(e/2, 2)` where `e` is even.

Observed risk from public hint: a broad product-distribution change can turn
this into `0`, which is wrong because `e/2` may be odd.

Expected: remain unevaluated enough that substituting `e = 6` gives
`Mod(3, 2)`, not `0`.

V1 status: resolved by guard. `as_coeff_Mul()` exposes the rational coefficient
`1/2`, so `cp.is_Integer` is false and the V1 branch is not taken.

Related proof obligations: PO3.

## F3: Symbolic-divisor and float behavior are frame conditions

Inputs: examples such as `(x - 3.3) % 1`, `Mod(5.0*x, 0.1*y)`, and products
modulo symbolic divisors such as `(12*x) % (2*y)`.

Observed risk from public discussion: reducing factors modulo only the numeric
part of a non-integer or symbolic divisor changes behavior outside the reported
integer case.

Expected: existing float and symbolic-divisor paths remain controlled by the
legacy float/gcd/additive logic.

V1 status: resolved by guard. The new branch requires integer numeric
coefficients and requires the divisor tail to be exactly `S.One`; floats and
symbolic divisors fail those conditions.

Related proof obligations: PO4, PO5.

## F4: Full `Mod.eval` proof is outside the mini-K model

Input class: all other `Mod.eval` branches, including denesting, additive
simplification, non-rational float extraction, gcd extraction, and delegated
`_eval_Mod` hooks.

Observed limitation: the FVK mini-K artifact models the new coefficient
normalization branch, not the full SymPy expression system.

Expected: do not claim machine-checked correctness for all of `Mod.eval`.

V1 status: no source change. This is a proof-scope limitation rather than a
newly justified code bug. The FVK decision only confirms the V1 branch against
the issue intent and public hint frame conditions.

Related proof obligations: PO6, PO7.

## F5: No FVK-driven source edit after V1

Input: the V1 code in `repo/sympy/core/mod.py` lines 177-183.

Observed: the guard matches the derived domain: integer coefficient, integer
plain divisor, and integer tail.

Expected: if those guards are sufficient for the congruence proof and block the
publicly warned cases, V1 may stand.

V1 status: confirmed unchanged. No additional production edit was justified by
the FVK obligations.

Related proof obligations: PO1 through PO5.
