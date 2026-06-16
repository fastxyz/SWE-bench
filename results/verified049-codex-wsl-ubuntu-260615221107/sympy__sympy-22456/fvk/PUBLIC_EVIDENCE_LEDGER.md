# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "`codegen.ast` `String` class does not support argument invariance like `expr.func(*expr.args) == expr`" | `String` must satisfy positional `Basic` reconstruction from `.args`. | Encoded as PO1 and PO2. |
| E2 | `benchmark/PROBLEM.md` | "The former should hold for any `Basic` subclass, which `String` is." | The fix must align with `Basic` conventions, not only make a one-off constructor shortcut. | Encoded as PO1 and PO2. |
| E3 | [repo/sympy/core/basic.py:124](/home/patrickmao/.swe-fvk-runs/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22456/repo/sympy/core/basic.py:124) | "all items in args must be Basic objects" | `.args` must not contain a raw Python `str`. | Encoded as PO1; rejects the raw-string alternative. |
| E4 | [repo/sympy/core/symbol.py:21](/home/patrickmao/.swe-fvk-runs/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22456/repo/sympy/core/symbol.py:21) | `Str` represents string data in SymPy. | Use `Str(text)` as the Basic-compatible reconstruction carrier. | Encoded as PO1. |
| E5 | [repo/sympy/codegen/tests/test_ast.py:264](/home/patrickmao/.swe-fvk-runs/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22456/repo/sympy/codegen/tests/test_ast.py:264) | Public test checks `is_Atom`, `.text`, kwargs reconstruction, subclass distinction, `str`, and `repr`. | Preserve current public `String` surface behavior. | Encoded as PO3, PO4, and PO6. |
| E6 | [repo/sympy/core/tests/test_args.py:97](/home/patrickmao/.swe-fvk-runs/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22456/repo/sympy/core/tests/test_args.py:97) | Public `_test_args` checks all args are `Basic` and reconstructability for non-empty `.args`. | The fix must satisfy both Basic argument type and reconstruction requirements. | Encoded as PO1 and PO2. |
| E7 | [repo/sympy/codegen/tests/test_cnodes.py:75](/home/patrickmao/.swe-fvk-runs/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22456/repo/sympy/codegen/tests/test_cnodes.py:75) | Public test expects `sizeof(...).atoms()` to return codegen `String` leaves. | Atom traversal must not expose internal `Str` wrappers in codegen default atom scans. | Encoded as PO5. |
| E8 | [repo/sympy/codegen/ast.py:213](/home/patrickmao/.swe-fvk-runs/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22456/repo/sympy/codegen/ast.py:213) | `Token.__new__` processes positional/keyword slots and omits `not_in_args` from `Basic` args. | V0 root cause: `String.text` was omitted from `.args`; V1 must supply an equivalent Basic argument. | Encoded as F1 and PO1. |

No hidden tests, evaluator data, internet sources, or upstream patches were used.
