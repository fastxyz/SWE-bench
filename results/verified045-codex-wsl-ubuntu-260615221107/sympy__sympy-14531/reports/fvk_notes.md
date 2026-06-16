# FVK Notes

## Decision

V1 was improved. `fvk/FINDINGS.md` F2 and F3 confirm that V1's `_print_Limit` and `_print_Relational` changes discharge the examples from the issue, but F1 shows V1 was incomplete against the broader recursive-printer obligation: several other `StrPrinter` methods still interpolated SymPy operand fields directly.

## Source Changes

All code changes are in `repo/sympy/printing/str.py`.

- Kept the V1 `_print_Limit` change. This is justified by F2 and `PROOF_OBLIGATIONS.md` PO-LIMIT: `e`, `z`, and `z0` must be printed through the active printer so `sympy_integers=True` reaches nested rationals.
- Kept the V1 equality-like `_print_Relational` change. This is justified by F2, F3, PO-REL, and PO-PYTHON: `lhs` and `rhs` must be printed recursively both for nested rational formatting and for PythonPrinter symbol collection.
- Changed `_print_AppliedPredicate` to print both predicate and argument through `self._print(...)`. This follows F1 and PO-FAMILY: the argument is a nested SymPy operand, and the predicate already has a printer method.
- Changed `_print_ExprCondPair` to print `expr` and `cond` through `self._print(...)`. This follows F1 and PO-FAMILY because Piecewise pairs can contain nested expressions and relational conditions that must preserve active settings.
- Changed `_print_Interval` to print endpoints through `self._print(...)`. This follows F1 and PO-FAMILY because endpoints are SymPy expressions and can include rationals or integers affected by `sympy_integers=True`.
- Changed `_print_Lambda` to print the bound variable(s) and body through `self._print(...)`. This follows F1 and PO-FAMILY because the body is a nested expression and the variable path should preserve PythonPrinter traversal semantics.
- Changed `_print_MatrixElement` to print indices through `self._print(...)`. This follows F1 and PO-FAMILY because the observable index fields are nested SymPy operands in the printer method.
- Changed `_print_Normal` and `_print_Uniform` to print distribution parameters through `self._print(...)`. This follows F1 and PO-FAMILY because those parameters are nested SymPy expressions.

## Decisions To Keep V2 Bounded

F4 and PO-FRAME justify not replacing every direct `str(...)` or raw interpolation in `StrPrinter`. Some methods delegate to specialized domain renderers, permutation array forms, or metadata rather than composing ordinary SymPy operand fields. The FVK spec therefore proves a bounded operand-composition family instead of asserting a global rewrite of all string conversion.

No tests were run or modified. The FVK proof is constructed, not machine-checked, as recorded in `fvk/PROOF.md` and `fvk/PROOF_OBLIGATIONS.md`.
