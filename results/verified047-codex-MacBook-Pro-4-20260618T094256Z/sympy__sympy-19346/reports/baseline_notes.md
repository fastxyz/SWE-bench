# Baseline Notes

## Root cause

`ReprPrinter` had explicit recursive printers for Python `list` and `tuple`, but not for Python `dict`, `set`, or `frozenset`. As a result, those containers fell through to the generic fallback, which ultimately used their normal Python string form. That form displayed SymPy objects as `x` and `y` instead of recursively using `srepr` output such as `Symbol('x')` and `Symbol('y')`.

## Changed files

`repo/sympy/printing/repr.py`

- Imported `default_sort_key` so unordered containers can be printed deterministically, matching existing printing conventions in other SymPy printers.
- Added `_print_dict` so plain dictionaries recursively print keys and values with `ReprPrinter`.
- Added `_print_Dict` so SymPy's immutable `Dict` wrapper also benefits from recursive item printing while preserving an eval-friendly `Dict(...)` representation.
- Added `_print_set` and `_print_frozenset` so set members are recursively printed and empty containers use valid Python constructor forms.

## Assumptions and rejected alternatives

- I assumed the issue refers primarily to built-in Python `dict` and `set`, because the examples pass literal containers directly to `srepr`.
- I kept ordering deterministic with `default_sort_key` rather than preserving hash or insertion order. Sets have no insertion order, and other SymPy printers already sort dict keys and set members for stable output.
- I included `frozenset` because it is the immutable counterpart of `set` and would otherwise have the same recursive-printing defect.
- I rejected changing the generic fallback printer because that would affect many unrelated objects. Adding explicit container printers is narrower and matches the existing list and tuple implementation style.
- I did not modify tests or run code, in accordance with the task constraints.
