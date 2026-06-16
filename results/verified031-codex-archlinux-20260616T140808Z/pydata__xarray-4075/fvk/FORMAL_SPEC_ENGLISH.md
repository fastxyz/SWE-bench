# Formal Spec English

This file paraphrases `fvk/weighted-spec.k`.

## Claims

1. `needsCast(boolKind, boolKind) => true`: the reducer must take the cast path
   exactly when both operands are boolean.
2. `needsCast(boolKind, otherKind) => false`, `needsCast(otherKind, boolKind)
   => false`, and `needsCast(otherKind, otherKind) => false`: mixed
   boolean/numeric and non-boolean paths are outside the new cast and retain
   existing dot behavior.
3. `reduceBoolBool(BS, WS) => dot01(BS, WS)` for equal-length lists: a
   boolean/boolean reducer returns the integer sum of 0/1 products.
4. `sumOfWeightsBool(BS, WS) => SomeWeight(dot01(BS, WS))` when the count is
   nonzero: the normalization denominator for boolean weights is the numeric
   count of valid true weights.
5. `sumOfWeightsBool(BS, WS) => NoWeight` when the count is zero: zero total
   weight remains invalid/missing.
6. The issue input rewrites to `Ratio(2, 2)`: data `[1, 1, 1]`, all-valid mask,
   and boolean weights `[true, true, false]` produce numerator `2` and
   denominator `2`, representing mean `1`.

## Frame Conditions

- No public method signature, argument name, return helper type, or virtual
  dispatch shape changes.
- The proof is about the boolean/boolean dot bug. Numeric-weight and mixed
  dtype reductions are framed by the `needsCast` claims and the source guard.
