# Baseline Notes

## Root cause

`ArithmeticPostAggregator` only registered the arithmetic functions `+`, `-`, `*`, `/`, and `quotient` in its internal `Ops` enum. Query JSON using `"fn": "pow"` failed validation in the constructor because `Ops.lookup("pow")` returned `null`, so exponentiation could not be used as a native arithmetic post-aggregator operation.

## Files changed

- `repo/processing/src/main/java/org/apache/druid/query/aggregation/post/ArithmeticPostAggregator.java`
  - Added a `POW` operation with function name `pow`.
  - Implemented the operation with `Math.pow(lhs, rhs)`.
  - Marked `POW` as preserving field order in cache keys, since `pow(a, b)` is not equivalent to `pow(b, a)`.

## Assumptions and alternatives

- I treated `pow` as a native arithmetic post-aggregator function name, matching the issue title and proposal. I did not add a separate `power` alias because the concrete requested function name was `pow`, and adding aliases would broaden the query surface beyond the issue.
- I kept the existing left-to-right folding behavior for arithmetic post-aggregators. For more than two fields, `pow` therefore evaluates as repeated binary exponentiation in field order, consistent with the class contract used by the other non-commutative operations.
- I did not change documentation or tests because the task requires a non-test source-code fix and the benchmark uses a fixed hidden test suite.
- I did not run tests or code, per the benchmark instructions.
