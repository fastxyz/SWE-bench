# Baseline Notes

## Root cause

`PythonCodePrinter` builds its supported plain Python function printers from the `_known_functions` table in `sympy/printing/pycode.py`. That table only mapped `Abs` to the Python builtin `abs`, so `Min` and `Max` fell through to the generic unsupported-function path in `CodePrinter._print_Function`. As a result, `pycode(Min(...))` and `pycode(Max(...))` emitted an unsupported-function comment instead of valid Python builtin calls.

## Files changed

- `repo/sympy/printing/pycode.py`: added `Max -> max` and `Min -> min` to `_known_functions`. This uses the existing known-function printer registration to produce `max(...)` and `min(...)` for plain Python code generation.

## Assumptions and alternatives considered

- I assumed the intended target for plain `pycode` is Python's builtin variadic `min` and `max`, matching the issue description and the behavior of other code printers that map `Min`/`Max` to native language functions.
- I considered adding explicit `_print_Min` and `_print_Max` methods to `PythonCodePrinter`, but rejected that because the existing known-function mechanism already handles simple function-call mappings and keeps the change smaller.
- I considered changing rewrite behavior in `CodePrinter._rewriteable_functions`, but rejected that because rewriting `Min`/`Max` to `Piecewise` is a fallback for unsupported targets and does not address the direct Python builtin support requested here.
- I did not modify tests, and I did not run tests or project code, per the benchmark instructions.
