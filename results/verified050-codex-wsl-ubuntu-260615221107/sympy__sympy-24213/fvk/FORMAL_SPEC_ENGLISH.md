# Formal Spec English

The K claims in `collect-factor-and-dimension-spec.k` mean:

1. For an addition whose first collected addend is
   `(F1, accelerationTime)` and second collected addend is `(F2, velocity)`,
   under a unit system with a dimension system, collection finishes with
   `ok(F1 + F2, accelerationTime)`.

2. More generally, for an addition whose first collected addend is `(F, D)` and
   whose remaining addends are all compatible with `D` under the active
   dimension system, collection finishes with the sum of all factors and returns
   `D` as the dimension.

3. For a unit system with a dimension system, adding `length` and `time` fails
   with a dimension error rather than producing a factor/dimension result.

4. For a unit system without a dimension system, `accelerationTime` and
   `velocity` are not accepted merely because a different unit system could
   relate them; direct equality remains the fallback predicate.

All claims are constructed, not machine-checked.
