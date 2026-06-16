# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Integer coefficient congruence

Claim: for all integers `C`, `Q`, and `T` with `Q != 0`,
`Mod(C*T, Q) == Mod((C % Q)*T, Q)` under Python's modulo convention.

Public basis: `Mod` uses Python's remainder sign convention, and the issue
requires reducing `3*i` modulo `2`.

Constructed proof status: discharged by arithmetic in `fvk/PROOF.md`. Encoded
as `checkEquivalent(C,T,Q) => true` in `fvk/sympy-mod-spec.k`.

## PO2: Reported instance

Claim: when `C = 3`, `Q = 2`, and `T` is an integer symbolic tail, the V1
normalization result is `modExpr(T, 2)`, corresponding to `Mod(i, 2)`.

Public basis: the problem statement explicitly requires
`Mod(3*i, 2) == Mod(i, 2)`.

Constructed proof status: discharged by PO1 plus `3 % 2 = 1`. Encoded as
`reduceCoeff(3,T,2,true,true,true) => modExpr(T,2)`.

## PO3: Rational-coefficient denominator exclusion

Claim: when the extracted coefficient is not an integer, the V1 branch is not
taken.

Public basis: the public hint says `Mod(e/2, 2)` for even `e` must not become
`0`, because `e/2` may be odd.

Constructed proof status: discharged by static guard inspection. Encoded as
`reduceCoeff(C,T,Q,false,true,true) => unchanged`.

## PO4: Non-integer or unknown-integer tail exclusion

Claim: reducing a coefficient modulo `Q` is only applied when the remaining
tail is known integer.

Public basis: modular congruence multiplication by the tail is justified in
integer arithmetic; it is not valid for arbitrary real or symbolic non-integer
tails.

Constructed proof status: discharged by static guard inspection. Encoded as
`reduceCoeff(C,T,Q,true,true,false) => unchanged`.

## PO5: Plain integer divisor exclusion

Claim: the branch applies only when the divisor has no remaining symbolic
factor after `as_coeff_Mul()`.

Public basis: existing public tests cover symbolic divisors such as `2*y`, and
reducing a coefficient modulo only the numeric part of `2*y` is not justified
by the issue.

Constructed proof status: discharged by static guard inspection. Encoded as
`reduceCoeff(C,T,Q,true,false,true) => unchanged`.

## PO6: Compatibility frame

Claim: V1 changes no public API, method signature, virtual dispatch protocol,
or test file; it only changes an internal construction-time simplification
inside `Mod.eval`.

Public basis: the task forbids test edits and asks for a source fix; the issue
is about the returned expression form for `Mod`.

Constructed proof status: discharged by static diff inspection.

## PO7: Proof-scope honesty

Claim: the constructed proof confirms only the new coefficient-normalization
obligation and its guard frame conditions; it does not prove all legacy
branches of `Mod.eval`.

Public basis: FVK's honesty gate requires explicit scope and "constructed, not
machine-checked" labeling.

Constructed proof status: recorded as a limitation in `fvk/FINDINGS.md` and
`fvk/PROOF.md`; no production edit is implied.
