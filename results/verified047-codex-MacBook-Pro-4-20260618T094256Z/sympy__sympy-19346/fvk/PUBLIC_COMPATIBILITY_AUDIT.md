# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols and dispatch shape

`repo/sympy/printing/repr.py`

- Added import: `default_sort_key`.
- Added private printer dispatch method: `ReprPrinter._print_dict`.
- Added private printer dispatch method: `ReprPrinter._print_Dict`.
- Added private printer dispatch method: `ReprPrinter._print_set`.
- Added private printer dispatch method: `ReprPrinter._print_frozenset`.

No public function signature changed. `srepr(expr, **settings)` remains unchanged.

## Public callsites and subclasses inspected

| Symbol | Public consumer or subclass | Compatibility result |
|---|---|---|
| `ReprPrinter._print_dict` | `Printer._print` dispatch for `dict` and dict subclasses | Newly handles the bug path; uses existing printer recursion for keys and values. |
| `ReprPrinter._print_set` | `Printer._print` dispatch for `set` | Newly handles the bug path; empty set spelling remains `set()`. |
| `ReprPrinter._print_frozenset` | `Printer._print` dispatch for `frozenset` | New behavior mirrors existing StrPrinter convention and remains eval-friendly. |
| `ReprPrinter._print_Dict` | `Printer._print` dispatch for SymPy `Dict` | Preserves wrapper with `Dict({...})`; avoids degrading to a plain Python dict. |
| New inherited methods | `PythonPrinter(ReprPrinter, StrPrinter)` | No signature conflict. Recursive member printing still calls `PythonPrinter._print_Symbol`, so PythonPrinter symbol declarations remain the producer of symbol spelling. |

## Override search result

Textual search found no other subclasses of `ReprPrinter` beyond `PythonPrinter`. `StrReprPrinter` and vector string repr printers derive from string printers, not `ReprPrinter`.

## Compatibility conclusion

No public callsite, subclass, or override requires a code change beyond V1. The only behavior changes are the intended new container dispatch paths and the eval-friendly SymPy `Dict` wrapper spelling.
