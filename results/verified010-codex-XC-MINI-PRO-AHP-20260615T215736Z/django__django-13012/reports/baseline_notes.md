# Baseline Notes

## Root cause

`ExpressionWrapper` delegates SQL generation to its wrapped expression, but it did
not delegate group-by column resolution. As a result it inherited
`BaseExpression.get_group_by_cols()`, which returns `[self]` for non-aggregate
expressions. Wrapping a constant `Value(...)` therefore made Django group by the
wrapper expression even though `Value.get_group_by_cols()` correctly returns
`[]`.

## Changed files

- `repo/django/db/models/expressions.py`: Added
  `ExpressionWrapper.get_group_by_cols()` and delegated to the wrapped
  expression's `get_group_by_cols(alias=alias)`. This preserves the wrapped
  expression's existing grouping behavior, including omitting constants from
  `GROUP BY`.

## Assumptions and alternatives considered

- Assumed `ExpressionWrapper` should behave transparently for grouping, the same
  way it already behaves for SQL rendering through `as_sql()`.
- Considered special-casing `Value` inside `ExpressionWrapper`, but rejected it
  because the grouping decision already belongs to each expression class.
- Considered changing `BaseExpression.get_group_by_cols()`, but rejected it as
  too broad: the bug is specific to a wrapper that should defer to its child.
- No tests or project code were run, per the benchmark instructions.
