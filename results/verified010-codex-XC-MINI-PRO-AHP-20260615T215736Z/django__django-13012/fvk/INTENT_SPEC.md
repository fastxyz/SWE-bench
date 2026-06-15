# Intent Specification

1. `ExpressionWrapper` must not change the group-by semantics of its wrapped
   expression.
2. Constants represented by `Value(...)` must contribute no group-by columns,
   whether wrapped or unwrapped.
3. The wrapper must work for arbitrary query expressions, including
   alias-aware expressions.
4. Django 3.2's deprecation path for custom `get_group_by_cols()` overrides
   missing `alias=None` remains active when such an expression is wrapped.
5. The fix is production-code only; test files are not modified in this
   benchmark.
