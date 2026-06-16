# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Membership Soundness for Reported Value

For `S1 = imageset(Lambda(n, n + (n - 1)*(n + 1)*I), S.Integers)`,
prove `contains(2, S1.intersect(S.Reals)) == False`.

Discharge: `2` is not in `FiniteSet(-1, 1)`. Satisfied by V1 if PO2 holds.

## PO2 - Exact Reported Intersection

For the reported `S1`, prove `S1.intersect(S.Reals) == FiniteSet(-1, 1)`.

Sub-obligations:

- `re(n) = n`.
- `im(n) = (n - 1)*(n + 1)`.
- `im(n) == 0` iff `n in FiniteSet(-1, 1)`.
- `base_set.intersect(FiniteSet(-1, 1)) == FiniteSet(-1, 1)`.
- `imageset(Lambda(n, n), FiniteSet(-1, 1)) == FiniteSet(-1, 1)`.

Discharge: V1 meets this by using `base_set.intersect(real_solutions)` and
`FiniteSet(*xis)`.

## PO3 - Denominator Exclusion Frame

For `ImageSet(Lambda(n, 1/n), S.Integers).intersect(S.Reals)`, prove the result
excludes `n = 0` from the base set and therefore does not equal the original
image over all integers.

Discharge: V1 uses denominator factors from each denominator expression and
subtracts their roots from the current result base.

## PO4 - Fallback Symbolic Correctness

When `im(n)` depends on `n` but linear-factor roots are not enumerated, prove the
symbolic result base is `ConditionSet(n, Eq(im, 0), base_set)`, not a complement
of that condition.

Discharge: V1 sets the base to that `ConditionSet`.

## PO5 - Public Compatibility

Prove no public API or dispatch signature changes are introduced.

Discharge: V1 edits only branch internals of an existing dispatched handler.

