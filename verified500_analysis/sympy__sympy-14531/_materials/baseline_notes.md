# Baseline Notes

## Root cause

`StrPrinter` had special-case methods that formatted some subexpressions by interpolating the raw SymPy objects directly. In `StrPrinter._print_Limit`, the limit expression, variable, and limit point were inserted with `%s`, which invokes the object's normal `str()` path and loses the current printer settings. In `StrPrinter._print_Relational`, equality-like relationals such as `Eq` and `Ne` did the same for `lhs` and `rhs`.

That bypasses options such as `sympy_integers=True`, so nested rationals print as `1/2` instead of `S(1)/2`. It also bypasses printer side effects in `PythonPrinter`: because `PythonPrinter` relies on `_print_Symbol` being called to collect symbol declarations, `python(Eq(x, y))` emitted `e = Eq(x, y)` without first declaring `x` and `y`.

## Files changed

`repo/sympy/printing/str.py`

Changed `_print_Limit` to print `e`, `z`, and `z0` through `self._print(...)` while preserving the existing `dir` display format. Changed the equality-like branch of `_print_Relational` to print `expr.lhs` and `expr.rhs` through `self._print(...)` before composing `Eq(...)`, `Ne(...)`, and assignment-style strings.

## Assumptions and alternatives considered

I assumed the issue is about preserving the active printer for nested SymPy expressions, not changing the public string shape of `Limit`, `Eq`, `Ne`, or assignment-style relationals. I kept `dir` in `Limit` formatted through its existing string conversion because it is used as a direction marker rendered inside quotes, and changing that would not address the reported loss of subexpression settings.

I considered broadly replacing every direct `%s` interpolation in `StrPrinter`, but rejected that as too large for this issue. Several printer methods intentionally delegate to domain-specific string representations, and changing all of them could alter unrelated output. The minimal fix covers the reported `Limit`, `Eq`, and `python(Eq(...))` failures by fixing the shared bypass in their printer methods.
