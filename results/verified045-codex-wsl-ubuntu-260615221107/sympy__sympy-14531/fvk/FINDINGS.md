# FINDINGS

Status: constructed, not machine-checked. Findings are from static code and proof-obligation analysis only.

## F1 - V1 fixed the reproductions but not the full recursive-printer obligation

Classification: code bug in V1; fixed in V2.

Evidence:

- `benchmark/PROBLEM.md` says printer settings are ignored by "certain subexpressions" and gives `Eq` and `Limit` examples.
- `repo/sympy/printing/printer.py` documents the nested-printer rule: custom printer code should use the active printer for nested expressions rather than `str()`.
- V1 changed `_print_Limit` and equality-like `_print_Relational`, but the same raw-operand pattern remained in `_print_AppliedPredicate`, `_print_ExprCondPair`, `_print_Interval`, `_print_Lambda`, `_print_MatrixElement`, `_print_Normal`, and `_print_Uniform`.

Concrete symbolic examples under V1:

- `sstr(Lambda(x, S(1)/2), sympy_integers=True)` would follow `_print_Lambda` and interpolate the body directly, deriving `Lambda(x, 1/2)`; expected under the active-printer obligation is `Lambda(x, S(1)/2)`.
- `sstr(Interval(S(1)/2, S(1)), sympy_integers=True)` would follow `_print_Interval` and interpolate endpoints directly, deriving `Interval(1/2, 1)`; expected is `Interval(S(1)/2, S(1))`.
- `sstr(ExprCondPair(S(1)/2, Eq(x, S(1)/2)), sympy_integers=True)` would interpolate the pair directly, deriving a condition/body string that can lose `S(...)`; expected is `(S(1)/2, Eq(x, S(1)/2))`.

V2 change:

Those methods now call `self._print(...)` for their SymPy operand fields, preserving active settings and PythonPrinter traversal side effects.

## F2 - Reported `Eq` and `Limit` failures are discharged by V1 and preserved by V2

Classification: confirmed fixed by static proof obligations.

Evidence:

- `_print_Relational` equality-like branch now formats `expr.lhs` and `expr.rhs` through `self._print(...)`.
- `_print_Limit` now formats `e`, `z`, and `z0` through `self._print(...)`.

Symbolic expected outcomes:

- `sstr(Eq(x, S(1)/2), sympy_integers=True)` reaches `_print_Rational` through `self._print` and yields `Eq(x, S(1)/2)`.
- `sstr(Limit(x, x, S(1)/2), sympy_integers=True)` reaches `_print_Rational` through `self._print` and yields `Limit(x, x, S(1)/2)`.

## F3 - `python(Eq(x, y))` depends on recursive traversal, not only string text

Classification: confirmed fixed by static proof obligations.

Evidence:

- `PythonPrinter._print_Symbol` appends symbol names to `printer.symbols`.
- `python()` emits declarations from `printer.symbols`.
- If `_print_Relational` interpolates raw operands, `_print_Symbol` is never called for `x` and `y`; if it calls `self._print`, both symbols are collected.

Symbolic expected outcome:

`python(Eq(x, y))` produces `x = Symbol('x')\ny = Symbol('y')\ne = Eq(x, y)`.

## F4 - Some direct string delegations remain intentionally outside this fix

Classification: accepted frame condition, not a current code change.

Evidence:

`StrPrinter` still contains direct formatting for domain-specific objects such as geometry entities, permutation internals, tensor-specific `_print()` methods, and category morphisms. The FVK obligation does not prove those paths.

Reason:

The issue and proof obligations justify changing raw interpolation of clear SymPy operand fields. They do not justify replacing every domain-specific string delegation in `StrPrinter`, because some methods intentionally delegate to another object's established textual representation.

Residual risk:

If future public intent requires `sympy_integers` or PythonPrinter symbol collection to propagate through one of those specialized domains, that domain should get its own targeted printer audit.
