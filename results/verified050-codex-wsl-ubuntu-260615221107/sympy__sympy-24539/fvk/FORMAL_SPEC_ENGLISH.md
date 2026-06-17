# Formal Spec English

Status: constructed, not machine-checked.

## POLY-AS-EXPR-DEFAULT

For every polynomial `P`, evaluating `polyAsExpr(P, noSymbols)` returns an
expression built from `asExprDict(P)` and `ringSymbols(P)`.

## POLY-AS-EXPR-SUPPLIED

For every polynomial `P` and supplied symbol list `SYMS`, if
`symbolLen(SYMS) == ringNgens(P)`, evaluating
`polyAsExpr(P, supplied(SYMS))` returns an expression built from
`asExprDict(P)` and the same supplied `SYMS`.

## POLY-AS-EXPR-BAD-ARITY

For every polynomial `P` and supplied symbol list `SYMS`, if
`symbolLen(SYMS) != ringNgens(P)`, evaluating
`polyAsExpr(P, supplied(SYMS))` returns the model's `valueError` result.

## FRAC-AS-EXPR-SUPPLIED

For every fraction with numerator `N` and denominator `D`, if the supplied
symbol list length matches the numerator generator count and numerator and
denominator have the same generator count, evaluating
`fracAsExpr(frac(N, D), supplied(SYMS))` returns the quotient of numerator and
denominator expressions, both built with the same supplied `SYMS`.

## Frame Conditions

The formal claims do not change the public signature. The only modeled
observable change from pre-fix behavior is the symbol list used on the
same-arity supplied-symbol branch.
