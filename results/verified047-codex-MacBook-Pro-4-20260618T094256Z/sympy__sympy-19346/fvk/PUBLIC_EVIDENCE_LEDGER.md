# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "`srepr` prints the element in `list` and `tuple` correctly" with `[Symbol('x'), Symbol('y')]` and `(Symbol('x'), Symbol('y'))` | Preserve recursive element printing and punctuation for list and tuple. | Encoded in list and tuple claims. |
| E2 | prompt | "`srepr` prints the elements in `dict` and `set` wrong" with `{x, y}` and `{x: y}` | Dict and set must not fall back to ordinary string forms for SymPy objects; their contents must recurse through the repr printer. | Encoded in dict and set claims. |
| E3 | repo/sympy/printing/repr.py docstring | "relation eval(srepr(expr))=expr holds in an appropriate environment" | Container output should remain eval-friendly where the represented object has an eval-friendly spelling. | Encoded in empty-container, frozenset, and SymPy Dict claims. |
| E4 | repo/sympy/printing/repr.py V1 | `_print_dict` sorts keys and prints key/value via `self._print`; `_print_set` sorts members and passes each through `reprify`; `_print_frozenset` wraps nonempty set output. | Candidate implementation mechanism recursively prints contents and uses valid constructors for empty/frozen cases. | Modeled by `reprOf(PyDict)`, `reprOf(PySet)`, and `reprOf(PyFrozenSet)`. |
| E5 | repo/sympy/printing/str.py, pretty.py, latex.py | Existing printers sort dict keys and set members with `default_sort_key`. | Deterministic ordering of unordered containers is a public compatibility convention, not an arbitrary hidden-test assumption. | Mirrored by abstract `sortVals` and `sortPairs`. |
| E6 | repo/sympy/printing/tests/test_repr.py | `sT` asserts `eval(srepr(expr)) == expr` for covered cases. | `srepr` changes should preserve eval-friendly output for newly handled container cases when possible. | Used to justify `Dict({...})` rather than degrading SymPy `Dict` to a plain dict. |
| E7 | repo/sympy/printing/python.py | `PythonPrinter(ReprPrinter, StrPrinter)` inherits `ReprPrinter` methods but overrides symbol spelling. | New private `ReprPrinter` methods must not break inherited PythonPrinter symbol output. | Addressed in public compatibility audit; no counterexample found. |
| E8 | prompt pre-fix display | `{x, y}` and `{x: y}` | These displays are reported as buggy and must not be enshrined as expected behavior. | Marked SUSPECT legacy behavior. |
