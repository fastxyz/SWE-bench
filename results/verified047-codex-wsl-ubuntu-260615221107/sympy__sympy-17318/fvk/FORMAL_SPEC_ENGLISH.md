# Formal Spec English

Status: constructed, not machine-checked.

1. The K claim `sqrtMatch(ISSUE-BASE-4I) => NO-MATCH` says that a flat complex
   additive base with rational but non-positive squared addends is not a valid
   `a + b*sqrt(r)` match.
2. The K claims for `splitSurds(ISSUE-DEN-4I)` and `splitSurds(CBRT-DEN)` say
   that additive expressions with no `S.Half` power terms return a neutral split
   `(1, 0, expr)`.
3. The K claim for `splitGcd(.List)` says empty helper input is total and
   returns the neutral gcd split.
4. The K claims for `radRationalize(ONE, ISSUE-DEN-4I)` and
   `radRationalize(ONE, CBRT-DEN)` say no-surd additive denominators return
   unchanged.
5. The K claim for `radRationalize(ONE, SQRT2-PLUS-I)` says that the valid
   `sqrt(2) + I` square-root denominator still rationalizes to
   `(sqrt(2) - I, 3)` in the abstract model.
