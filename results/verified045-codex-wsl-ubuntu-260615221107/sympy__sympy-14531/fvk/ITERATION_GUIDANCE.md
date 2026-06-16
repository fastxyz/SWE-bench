# ITERATION_GUIDANCE

Status: constructed, not machine-checked.

## Decision

V1 should not stand unchanged. The audit found that V1 fixed the reported `Eq`, `Limit`, and `python(Eq(...))` examples, but left the same active-printer bypass in several other `StrPrinter` composite methods. V2 applies the same `self._print(...)` rule to those methods.

## Changes to Keep

Keep the V1 changes:

- `_print_Limit` prints `e`, `z`, and `z0` with `self._print(...)`.
- equality-like `_print_Relational` prints `lhs` and `rhs` with `self._print(...)`.

Keep the V2 refinements:

- `_print_AppliedPredicate`
- `_print_ExprCondPair`
- `_print_Interval`
- `_print_Lambda`
- `_print_MatrixElement`
- `_print_Normal`
- `_print_Uniform`

Each now prints operand subexpressions with the active printer.

## What Not To Change In This Iteration

Do not rewrite every `str(...)` call in `StrPrinter`. Some methods intentionally delegate to domain-specific string renderers or print non-SymPy metadata. Those paths are outside the current proof and should only be changed with specific public-intent evidence.

Do not modify tests. The benchmark requires production-source changes only, and the FVK proof is not machine-checked.

## Recommended Follow-Up Tests

If tests were allowed, add focused assertions for:

- `sstr(Eq(x, S(1)/2), sympy_integers=True) == "Eq(x, S(1)/2)"`
- `sstr(Limit(x, x, S(1)/2), sympy_integers=True) == "Limit(x, x, S(1)/2)"`
- `python(Eq(x, y)) == "x = Symbol('x')\ny = Symbol('y')\ne = Eq(x, y)"`
- one representative non-reported composite path such as `Lambda` or `Interval` with `sympy_integers=True`.

No test should be removed based on this FVK pass unless the K claims are adapted as needed and `kprove` returns `#Top`.
