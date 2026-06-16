# Intent Specification

Status: intent-first, constructed from public evidence only. This is not
machine-checked.

## Target

The audited unit is the `ImageSet` with `S.Reals` branch in
`repo/sympy/sets/handlers/intersection.py::intersection_sets(self, other)`.

## Public Intent Obligations

1. For `S1 = imageset(Lambda(n, n + (n - 1)*(n + 1)*I), S.Integers)`,
   `2 in S1` is false and `2 in S1.intersect(S.Reals)` must also be false.

2. For the same `S1`, `S1.intersect(S.Reals)` must evaluate to the finite set
   `FiniteSet(-1, 1)`, printed in the issue as `{-1, 1}`.

3. The real-intersection branch must keep exactly parameter values whose image
   has zero imaginary part. For a univariate image expression
   `re(n) + I*im(n)`, the real portion is the image of `re(n)` over
   `base_set intersect {n in base_set | im(n) == 0}`, excluding undefined
   denominator points.

4. Values that make the lambda expression undefined are not evidence that the
   image set is a subset of `S.Reals`. The public in-repo test for
   `imageset(Lambda(n, 1/n), S.Integers).is_subset(S.Reals) is None` records
   this compatibility constraint from issue #19513.

5. Existing public tests or legacy displays that encode
   `Complement(S.Integers, FiniteSet((-1, 1)))` for the reported expression are
   SUSPECT, because the issue explicitly labels that behavior incorrect and
   gives `{-1, 1}` as the correct output.

## Domain Assumptions

- The audited path is the existing univariate `ImageSet` intersection handler.
- The public issue fixes behavior for the expression shown and the general
  algebraic obligation it exercises: real intersection keeps zero-imaginary
  parameters, not their complement.
- When zero roots cannot be enumerated by the current linear-factor routine, an
  exact `ConditionSet` over the current base set is an acceptable symbolic
  representation.

