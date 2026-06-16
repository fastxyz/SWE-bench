# FVK Spec: `Mod` Integer Coefficient Reduction

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

The audited production change is the V1 branch in
`repo/sympy/core/mod.py` lines 177-183. It runs after `p.as_coeff_Mul()` and
`q.as_coeff_Mul()` split a dividend into numeric coefficient `cp` and tail `p`,
and a divisor into numeric coefficient `cq` and tail `q`.

This FVK pass does not model every legacy simplification in `Mod.eval`. It
formalizes the arithmetic obligation introduced by V1 and the guard conditions
that keep the public hint corner cases on the previous code path.

## Intent-Only Obligations

I1. Default-path result: the issue states that bare `Mod(3*i, 2)` should reduce
to `Mod(i, 2)` for integer `i`.

I2. Python modulo convention: the `Mod` docstring says the remainder has the
same sign as the divisor. The formal model therefore uses
`C - Q * floor(C / Q)` for integer modulo.

I3. Denominator guard: the public hint says a broad product distribution is
wrong for `Mod(e/2, 2)` when `e` is even, because `e/2` may be odd.

I4. Float and symbolic-divisor frame: the public discussion calls out
`(x - 3.3) % 1` as a corner case to avoid disturbing, and existing public tests
cover float and symbolic-divisor behavior near `test_arit.py` lines 1540-1623.

I5. Minimal compatibility: no public API, signature, return type protocol, or
dispatch shape should change. Only construction-time simplification inside
`Mod.eval` may change.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`Mod(3*i, 2)` should reduce to `Mod(i, 2)`" | postcondition for integer coefficient `3`, integer divisor `2`, integer tail `i` | encoded by PO1, PO2 |
| E2 | docs | `Mod` docstring: remainder has same sign as divisor | use Python integer modulo semantics | encoded by `pyMod` |
| E3 | hint | "`Mod(var('e',even=True)/2,2)==0` ... should remain unevaluated" | rational-coefficient denominators must not enter the reduction | encoded by PO3 |
| E4 | hint | "`e/2` ... An even number divided by 2 may or may not be even" | `is_integer` tail alone is not enough if the extracted coefficient is non-integer | encoded by PO3 |
| E5 | hint/public tests | "`(x - 3.3) % 1`" and float tests in `test_arit.py` | float paths and additive float normalization are frame conditions | encoded by PO4 |
| E6 | public tests | symbolic divisor/gcd examples in `test_arit.py` lines 1610-1623 | do not reduce coefficient modulo only the numeric part of a symbolic divisor | encoded by PO5 |

## Formal Contract

Let `C` and `Q` be integer numeric coefficients, `Q != 0`, and let `T` be the
remaining dividend tail known to be integer. Let `r = C % Q` using Python's
modulo convention.

Preconditions for the V1 branch:

- `cp.is_Integer` is true;
- `cq.is_Integer` is true;
- the divisor tail after `q.as_coeff_Mul()` is exactly `S.One`;
- the dividend tail after `p.as_coeff_Mul()` is known integer;
- the earlier zero-divisor guard has excluded `Q = 0`.

Postcondition:

- replacing the candidate dividend `C*T` with `r*T` preserves the value of the
  outer modulo operation: `Mod(C*T, Q) == Mod(r*T, Q)`;
- in the reported instance `C = 3`, `Q = 2`, `T = i`, the reconstructed result
  is `Mod(i, 2)`;
- if any precondition fails, the V1 branch is not taken and the previous
  normalization path is preserved.

## Adequacy Audit

The K claims in `fvk/sympy-mod-spec.k` paraphrase the intent as follows:

- `checkEquivalent(C,T,Q) => true` states the general integer congruence.
  This matches I1 and I2 and is not implementation-derived.
- `reduceCoeff(3,T,2,true,true,true) => modExpr(T,2)` states the reported
  example. This matches E1 exactly.
- the three `unchanged` claims state that rational/non-integer coefficients,
  non-plain divisors, and non-integer tails do not use the V1 reduction. These
  match E3-E6.

No claim preserves the pre-fix behavior `Mod(3*i, 2)` unchanged; that displayed
behavior is the reported bug and is SUSPECT legacy behavior under FVK.

## Formal Files

- `fvk/mini-sympy-mod.k`: mini-K fragment for the V1 branch and modulo
  equivalence helper.
- `fvk/sympy-mod-spec.k`: K claims with `SPEC-PROVENANCE` comments.

The commands to machine-check later are listed in `fvk/PROOF.md`. They were not
run in this session.
