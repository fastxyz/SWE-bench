# Formal Spec, Paraphrased

Status: constructed, not machine-checked.

## Claim C1: Reported Real Intersection

For the abstract image `Image(IssueExpr, Integers)`, where `IssueExpr` models
`n + I*(n - 1)*(n + 1)`, `intersectReals` rewrites to `IssueResult`, the model's
name for `FiniteSet(-1, 1)`.

## Claim C2: Nonmembership of 2

For the same intersection result, `contains(2, result)` rewrites to `false`.

## Claim C3: Membership of the Roots

For the same intersection result, `contains(-1, result)` and
`contains(1, result)` rewrite to `true`.

## Claim C4: Denominator Exclusion Frame

For the abstract image `Image(OneOverN, Integers)`, `intersectReals` rewrites to
the image over `NonZeroIntegers`, not over all `Integers`. This paraphrases the
compatibility obligation that undefined denominator points are excluded and
therefore `is_subset(S.Reals)` must not be forced to true by treating `1/0` as a
real value.

## Side Conditions

The formal model treats `zeroSet(IssueImag)` as `IssueRoots`, corresponding to
the algebraic fact that `(n - 1)*(n + 1) = 0` iff `n` is `-1` or `1`.

