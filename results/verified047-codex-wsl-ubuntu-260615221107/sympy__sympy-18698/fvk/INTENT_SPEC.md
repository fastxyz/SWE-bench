# Intent Spec

Status: intent-only, derived before accepting V1 behavior as correct.

## Required Behavior

1. `sqf_list()` on a univariate polynomial expression must return a square-free
   factor list with one factor per multiplicity.

2. If several factors have the same multiplicity, the returned factor for that
   multiplicity must be their product. For the reported expression, the two
   factors of multiplicity `3`, `x - 3` and `x - 2`, must be returned as
   `x**2 - 5*x + 6` with multiplicity `3`.

3. `sqf_list()` should stay consistent with the `Poly(...).sqf_list()` convention
   for univariate input.

4. The ordinary `factor_list()` contract is different: it returns irreducible
   factors and must not be changed to combine factors by square-free
   multiplicity.

5. The square-free public helpers are intended for univariate polynomials. A
   generator may be omitted only when there is no ambiguity, such as an
   expression with one symbol.

## Ambiguous Or Non-Required Behavior

1. Multiple-generator or no-generator multivariate behavior is not fully
   specified by the public issue. The issue text says this behavior may be
   indeterminate and mentions that `ValueError` could be raised, but it does not
   establish a required behavior strong enough to override existing public API
   compatibility in this pass.

2. Constant expressions are discussed as a possible error case, but existing
   public behavior includes `sqf_list(1) == (1, [])`. The issue does not require
   changing constants to errors.
