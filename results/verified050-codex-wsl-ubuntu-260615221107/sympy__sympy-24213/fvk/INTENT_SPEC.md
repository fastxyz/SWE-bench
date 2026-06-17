# Intent Spec

Status: constructed from public issue text, in-repository source, and public
tests only. Hidden tests, evaluator output, internet access, previous runs, and
upstream fixes were not used.

## Required Behavior

1. `UnitSystem._collect_factor_and_dimension(expr)` must accept an `Add` when
   all addends have dimensions that are equivalent in the active
   `DimensionSystem`, even if their `Dimension` objects are not syntactically
   equal.

2. The reported SI case is in scope: `acceleration*time` and `velocity` both
   have dimensional dependencies `{length: 1, time: -1}` and therefore must be
   accepted in an addition.

3. The method must preserve existing behavior for physically incompatible
   additions: a mismatched addend should still raise `ValueError`.

4. On accepted additions, the method must keep its existing return shape:
   `(combined_factor, dimension)`, where `combined_factor` is the sum of the
   collected addend factors and `dimension` is the first accepted addend's
   dimension expression.

5. For a `UnitSystem` that has no dimension system, there is no public
   dependency map to consult. The compatibility predicate remains direct
   dimension equality.

## Out Of Scope

This audit does not specify unrelated branches of
`_collect_factor_and_dimension` beyond the frame condition that the fix must not
change them. It also does not prove termination or performance.
