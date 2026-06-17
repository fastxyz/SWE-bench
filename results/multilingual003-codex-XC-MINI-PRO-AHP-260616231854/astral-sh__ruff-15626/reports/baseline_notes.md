# Baseline Notes

## Root cause

SIM201 and SIM202 always attached their replacement with `Fix::safe_edit`. That is only correct when both comparison operands are known to have equality and inequality operators that return `bool`. For user-defined and third-party objects, `__eq__` and `__ne__` can return arbitrary objects, so rewriting `not a == b` to `a != b` or `not a != b` to `a == b` can change runtime behavior, as with NumPy arrays.

## Changed files

- `repo/crates/ruff_linter/src/rules/flake8_simplify/rules/ast_unary_op.rs`: Added fix-safety documentation for SIM201 and SIM202. Added a local applicability helper that marks the fix safe only when both operands resolve to Ruff's simple built-in expression types, known built-in constructors, or existing semantic helpers for built-in containers and numeric bindings. Both SIM201 and SIM202 now use `Fix::applicable_edit` with that computed applicability instead of always using `Fix::safe_edit`.

## Assumptions and alternatives

- I treated unknown names, arbitrary calls, user-defined classes, imports such as `np.array(...)`, and ambiguous shadowed bindings as unsafe because Ruff cannot prove their comparison methods return `bool`.
- I allowed safe fixes for simple built-in types recognized by Ruff's existing type inference, because those comparison operations return boolean results.
- I considered marking every SIM201 and SIM202 fix unsafe. That would fix the NumPy example, but it would be more conservative than the issue requests and would lose safe fixes for obvious built-in comparisons.
- I considered trusting all type annotations as exact runtime types. I rejected a broad annotation-only approach and limited the source of safe decisions to existing Ruff semantic helpers and inferable initializer expressions to keep the change targeted.
