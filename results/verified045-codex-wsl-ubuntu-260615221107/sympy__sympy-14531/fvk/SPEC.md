# SPEC

Status: constructed, not machine-checked. No tests, Python, or K tools were run.

## Scope

The audited production unit is `repo/sympy/printing/str.py`, specifically `StrPrinter` methods that compose printable strings from nested SymPy subexpressions, plus the inherited effect on `PythonPrinter` in `repo/sympy/printing/python.py`.

This FVK pass models the observable behavior needed for the issue:

- nested subexpressions must be printed through the active printer;
- `sympy_integers=True` must reach nested integer/rational printing;
- `PythonPrinter` must visit nested symbols so declarations are collected before the final expression.

## Intent Spec

1. `sstr(Eq(x, S(1)/2), sympy_integers=True)` must render the nested rational as `S(1)/2`, yielding `Eq(x, S(1)/2)`.
2. `sstr(Limit(x, x, S(1)/2), sympy_integers=True)` must render the limit point as `S(1)/2`, yielding `Limit(x, x, S(1)/2)`.
3. `python(Eq(x, y))` must visit the nested symbols and emit declarations for both before `e = Eq(x, y)`.
4. For composite `StrPrinter` methods, public printer behavior requires nested SymPy operands to be printed with `self._print(...)`; using direct `str()` or raw `%s` interpolation is not an intended special case unless a method is delegating to an explicitly domain-specific formatter.
5. Default string output shape should be preserved where no non-default settings or PythonPrinter side effects are involved.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "`sstr(Eq(x, S(1)/2), sympy_integers=True)` ... expected `Eq(x, S(1)/2)`" | Equality-like relational operands must use active printer settings. | Encoded in PO-REL. |
| E2 | prompt | "`sstr(Limit(x, x, S(1)/2), sympy_integers=True)` ... expected `Limit(x, x, S(1)/2)`" | Limit expression/variable/point operands must use active printer settings. | Encoded in PO-LIMIT. |
| E3 | prompt | "`python(Eq(x, y))` ... expected `x = Symbol('x')\ny = Symbol('y')\ne = Eq(x, y)`" | PythonPrinter must recursively visit operands of equality-like relationals. | Encoded in PO-PYTHON. |
| E4 | source docs | `repo/sympy/printing/printer.py` documents that nested printer methods should use the printer instead of `str()` so nested expressions work correctly. | Direct raw interpolation of SymPy operands in `StrPrinter` is suspect. | Encoded in PO-FAMILY. |
| E5 | source code | `PythonPrinter._print_Symbol` records symbols as a side effect, and `python()` emits declarations from that list. | Recursive `_print` calls are required not only for string form but also for declaration collection. | Encoded in PO-PYTHON and PO-FAMILY-PY. |
| E6 | V1 code audit | V1 fixed `_print_Limit` and equality-like `_print_Relational`, but left the same direct-subexpression pattern in `AppliedPredicate`, `ExprCondPair`, `Interval`, `Lambda`, `MatrixElement`, `Normal`, and `Uniform`. | V1 is incomplete against the generalized printer contract. | Finding F1; V2 edits applied. |
| E7 | implementation frame | Methods such as `_print_GeometryEntity`, permutation/group formatting, and category morphism formatting intentionally delegate to specialized object string forms rather than simple SymPy expression operands. | Do not rewrite every `str(...)` in `StrPrinter`; keep the fix bounded to clear operand composition. | Accepted frame condition. |

## Formal Model

The formal core is in:

- `fvk/mini-python-printing.k`
- `fvk/strprinter-spec.k`

The model abstracts SymPy objects to expression constructors such as `RelExpr`, `LimitExpr`, `Lambda1`, `IntervalExpr`, and `Rat`. `printStr(SI, expr)` represents `StrPrinter` with `sympy_integers=SI`. `pythonProgram(expr)` represents the relevant `PythonPrinter` behavior: collect symbols while printing recursively, then prepend declarations.

This model intentionally omits full Python and full SymPy semantics. It preserves the property under verification: whether a composite printer method recurses through `printStr` or bypasses it via `rawStr`.

## Formal Spec English

- PO-REL: for all equality-like relational operands in scope, the output is the constructor name (`Eq`/`Ne`) applied to the active-printer rendering of the left and right operands.
- PO-LIMIT: for `Limit`, `e`, `z`, and `z0` are rendered by the active printer; the direction string remains the existing quoted direction marker.
- PO-PYTHON: for `python(Eq(x, y))`, recursive printing visits both symbols and therefore produces declarations for `x` and `y` before the expression.
- PO-FAMILY: the same active-printer recursion is required for the audited composite methods whose operands are SymPy subexpressions: `AppliedPredicate`, `ExprCondPair`, `Interval`, `Lambda`, `MatrixElement`, `Normal`, and `Uniform`.
- PO-FRAME: default formatting shape and operator names remain unchanged; only operand rendering is delegated to the active printer.

## Adequacy Audit

| Obligation | Adequacy result |
|---|---|
| PO-REL | Pass. Directly matches E1 and preserves default constructor shape. |
| PO-LIMIT | Pass. Directly matches E2 and preserves existing direction rendering. |
| PO-PYTHON | Pass. Directly matches E3 and the documented `PythonPrinter._print_Symbol` collection mechanism. |
| PO-FAMILY | Pass with bounded scope. E4 gives the general nested-printer rule; E6 identifies concrete methods with the same operand bypass. E7 prevents over-broad rewriting of specialized object formatters. |
| PO-FRAME | Pass. The code changes do not alter signatures, constructor names, separators, or branch structure. |

## Public Compatibility Audit

No public function or method signatures changed. `sstr`, `StrPrinter`, `PythonPrinter`, and `python` keep their existing APIs. The changed methods remain internal printer dispatch methods with the same names and parameters.

The expected compatibility effect is behavioral: default output is preserved because the default active printer matches the old nested `str()` representation for ordinary SymPy operands. Non-default settings and PythonPrinter side effects now propagate to nested operands, which is the requested behavior change.
