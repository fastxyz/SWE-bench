# Intent Spec

Status: constructed, not machine-checked.

The public issue requires native arithmetic post-aggregators to support a new function named `pow`.

Required behavior:

1. `fn = "pow"` is accepted anywhere arithmetic post-aggregator function names are accepted.
2. `pow(lhs, rhs)` is equivalent to Java `Math.pow(lhs, rhs)` after the existing numeric conversion to double.
3. Constants such as `2`, `3`, and `0.5` can be used as exponents to express square, cube, and square root.
4. The existing arithmetic post-aggregator contract remains in force: fields are evaluated from left to right, any null field result makes the post-aggregator result null, and arithmetic results are floating-point/double values.
5. Since `pow` is order-sensitive, cache keys for `pow` post-aggregators must preserve field order.
6. The function spelling required by public intent is `pow`. The word `power` in later prose is treated as descriptive wording, not a second native function name.
