# Baseline Notes

## Root cause

`parse_expr(..., evaluate=False)` relies on `evaluateFalse` and
`EvaluateFalseTransformer` to rewrite selected Python AST operators into SymPy
constructor calls with `evaluate=False`. The transformer handled arithmetic
`ast.BinOp` nodes and selected function calls, but it did not handle
`ast.Compare` nodes. Python comparisons such as `1 < 2` were therefore left as
ordinary Python comparison syntax and evaluated to `True` before SymPy could
return an unevaluated relational. `sympify` inherits the same behavior for
strings because it delegates string parsing to `parse_expr`.

## Changed files

- `repo/sympy/parsing/sympy_parser.py`: added a comparison-operator map from
  Python AST comparison operator classes (`Eq`, `NotEq`, `Lt`, `LtE`, `Gt`,
  `GtE`) to the corresponding SymPy relational constructors (`Eq`, `Ne`, `Lt`,
  `Le`, `Gt`, `Ge`). Added `visit_Compare` so supported comparisons are
  rewritten as SymPy relational constructor calls with `evaluate=False`. Chained
  comparisons are rewritten as an unevaluated `And` of pairwise relationals so
  Python's comparison-chain truth evaluation is avoided under `evaluate=False`.

## Assumptions and alternatives

- Assumed `evaluate=False` should preserve all standard Python comparison
  relationals, including `==` and `!=`, not only strict inequalities.
- Assumed no separate `sympify` change is needed because string input to
  `sympify` already flows through `parse_expr`.
- Rejected adding comparison operators only to the existing `operators` map
  used by `visit_BinOp`, because Python comparison syntax is represented by
  `ast.Compare`, not `ast.BinOp`.
- Rejected changing the relational constructors themselves because direct calls
  such as `Lt(1, 2, evaluate=False)` already produce the desired unevaluated
  result.
- Did not modify tests, and did not run tests or project code, because the
  benchmark instructions forbid both.
