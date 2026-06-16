# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Quoted evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Support Post aggregation function pow(f1,f2)" | Support native arithmetic post-aggregator function name `pow`. |
| E2 | `benchmark/PROBLEM.md` | "equivalent to Math.pow()" | Pairwise operation delegates to Java `Math.pow`. |
| E3 | `benchmark/PROBLEM.md` | "Square ... pow(f1,2)" | Numeric constants are valid exponent operands. |
| E4 | `repo/docs/querying/post-aggregations.md` | "applies the provided function to the given fields from left to right" | Multi-field arithmetic post-aggregators fold left-to-right. |
| E5 | `repo/docs/misc/math-expr.md` | "`pow` ... `pow(x, y)` returns the value of the x raised to the power of y" | Existing Druid expression language spelling is `pow`. |
| E6 | `repo/sql/.../DruidOperatorTable.java` | `SqlStdOperatorTable.POWER, "pow"` | SQL `POWER` maps to internal expression function `pow`; this supports `pow` as the native spelling. |
| E7 | `ArithmeticPostAggregator.java` comment | "if any of the value is null, arithmetic operators will return null" | Preserve existing null propagation for `pow`. |
| E8 | cache semantics | `appendCacheablesIgnoringOrder` sorts field cache keys | Non-commutative operations must use ordered field cache keys. |
