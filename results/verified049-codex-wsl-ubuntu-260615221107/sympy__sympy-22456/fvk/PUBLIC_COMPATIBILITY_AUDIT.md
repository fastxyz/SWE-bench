# Public Compatibility Audit

Status: constructed, not machine-checked.

| Changed public symbol or protocol | Public compatibility question | Audit result |
|---|---|---|
| `sympy.codegen.ast.String.__new__` | Did the public call shape change? | No. It still accepts positional or keyword `text` through `Token.__new__`; V1 only installs a `Str(text)` Basic argument after validation. |
| `sympy.codegen.ast.String.text` | Does `.text` remain a Python `str`? | Yes by source inspection: `_construct_text` returns `text.name` for `Str` and returns the raw Python string for public `str`. |
| `String.kwargs()` | Does kwargs reconstruction remain available? | Yes. `Token.kwargs()` reads slots, so it still returns the public `.text` value. |
| `QuotedString`, `Comment`, user subclasses | Do subclasses reconstruct via `.args`? | Yes. They inherit `String.__new__` and `_construct_text`; `expr.func(*expr.args)` calls the subclass with `Str(text)`. |
| `Token.atoms()` | Does atom collection change outside codegen tokens? | No. V1 scopes default atom preservation to `Token.atoms()` and does not alter global `Basic.atoms()`. |
| Codegen helpers using `String(arg)` | Are producer callsites still compatible? | Yes. Helpers such as `_mk_Tuple`, `sizeof`, `alignof`, and Fortran helpers still pass Python strings or already-constructed `String` objects. |

No public override with an incompatible signature was found in the audited code
paths. No test files were modified.
