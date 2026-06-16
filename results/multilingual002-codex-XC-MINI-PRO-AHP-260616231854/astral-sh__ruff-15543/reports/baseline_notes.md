# Baseline Notes

## Root cause

UP028 builds its unsafe fix by slicing the original `for` loop iterable and prefixing it with `yield from`. For an unparenthesized tuple iterable like `for e in x,:`, the sliced iterable is the bare tuple source `x,`, so the fixer emits `yield from x,`. That is invalid Python syntax in statement position and does not preserve the required tuple expression context for `yield from`.

## Files changed

- `repo/crates/ruff_linter/src/rules/pyupgrade/rules/yield_in_for_loop.rs`: When the loop iterable is an `Expr::Tuple` whose AST node records `parenthesized: false`, the fixer now wraps the sliced iterable source in parentheses before constructing the `yield from` replacement. This preserves the existing source-slicing behavior for comments and formatting while producing `yield from (x,)` for the reported singleton tuple case and `yield from (x, y)` for other bare tuple iterables.

## Assumptions and alternatives

- I assumed the intended behavior is to keep applying UP028 to bare tuple iterables, because `yield from (x,)` is the direct equivalent of iterating over the tuple and yielding each loop target.
- I considered suppressing the fix for unparenthesized tuple iterables instead, but rejected it because the rule can still produce a correct and small replacement by adding parentheses.
- I considered changing the generic parenthesized-range helper, but rejected it because the bug is specific to the UP028 replacement context: bare tuple syntax is accepted in a `for ... in ...:` clause but must be parenthesized after `yield from`.
- Tests were not run, and no test files were modified, per the task constraints.
