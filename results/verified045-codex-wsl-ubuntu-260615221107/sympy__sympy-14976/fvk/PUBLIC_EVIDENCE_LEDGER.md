# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`lambdify(modules='mpmath')` doesn't wrap rationals" | The mpmath lambdify printer must wrap non-integer rationals instead of emitting bare Python rational division. | Encoded in `SPEC.md`, `mpmath-rational-printer-spec.k`, PO-2 |
| E2 | `benchmark/PROBLEM.md` | Generated source showed `RisingFactorial(18, x) - 232/3` | A non-integer rational constant in any generated expression contributor must print in wrapped mpmath form, including when nested under `Add` or as a rational coefficient. | Encoded in PO-2, PO-3, PO-7 |
| E3 | `benchmark/PROBLEM.md` | "This results in reduced precision results from `nsolve`, because the `232/3` isn't evaluated at full precision." | The generated rational expression must force mpmath arithmetic before precision-sensitive numeric solving consumes it. | Encoded in PO-2 and PO-5 |
| E4 | `repo/sympy/utilities/lambdify.py` | `if _module_present('mpmath', namespaces): ... MpmathPrinter` | The observable issue path reaches `MpmathPrinter` when `modules` contains `mpmath`. | Encoded in PO-1 |
| E5 | `repo/sympy/utilities/lambdify.py` | The mpmath namespace is built with `from mpmath import *` | For lambdified mpmath functions, unqualified `mpf` is available when the printer emits `mpf(...)`. | Encoded in PO-5 |
| E6 | `repo/sympy/printing/pycode.py` | `MpmathPrinter._print_Float` already uses `_module_format('mpmath.mpf')` | The local mpmath printer convention for precision-sensitive numeric literals is to emit `mpmath.mpf` through `_module_format`. | Encoded in PO-2 |
| E7 | `repo/sympy/core/numbers.py` | `Rational.__new__` flips negative denominators and returns `Integer` when `q == 1` | The rational printer can assume `q > 0`; integer-valued rationals are not the precision-loss division case. | Encoded in PO-4 |
| E8 | FVK source audit | The V1 patch adds `_print_Rational` only on `MpmathPrinter` | Non-mpmath printers are framed unchanged for this issue. | Encoded in PO-6 |

No hidden tests, upstream patches, benchmark results, or internet sources were used.
