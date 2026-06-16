# Baseline Notes

## Root Cause

`srepr` is implemented by `ReprPrinter` in `sympy/printing/repr.py`. The printer
had explicit recursive handlers for built-in `list` and `tuple`, but no handlers
for built-in `dict`, `set`, or `frozenset`. Because the base printer dispatch
looks for methods named from the object's Python class, plain dictionaries and
sets fell through to `emptyPrinter`, which ultimately used `str(expr)`. That
normal string formatting printed nested SymPy objects as `x` and `y` instead of
their `srepr` forms like `Symbol('x')` and `Symbol('y')`.

## Changed Files

`repo/sympy/printing/repr.py`

Added `default_sort_key` and new `_print_dict`, `_print_set`, and
`_print_frozenset` methods to `ReprPrinter`. The new methods recursively print
keys, values, and elements through the same repr printer, matching the existing
behavior for lists and tuples. Sets and dict keys are sorted with SymPy's
standard sort key so unordered containers produce stable output.

`reports/baseline_notes.md`

Added this report describing the root cause, the source change, assumptions, and
alternatives considered.

## Assumptions

The issue refers to Python built-in `dict` and `set` objects, as shown by the
literal examples `{x: y}` and `{x, y}`. I therefore targeted the built-in
container dispatch methods `_print_dict` and `_print_set`.

I treated `frozenset` as the same family of built-in container behavior because
it has the same recursive-printing problem and existing string/pretty printers
already handle it alongside `set`.

I preserved Python literal syntax for non-empty dictionaries and sets, used
`set()` for the empty set, and used `frozenset(...)` for frozensets so the output
remains an executable representation in an appropriate SymPy environment.

## Alternatives Considered

One alternative was changing `emptyPrinter` to detect all iterable objects and
recursively print them. I rejected that because it would broaden the behavioral
surface of `srepr` for arbitrary unknown objects and risk changing unrelated
fallback representations.

Another alternative was adding `_print_Dict` for SymPy's immutable `Dict`. I
rejected that because the reported failure concerns built-in `dict`, and changing
the `Dict` representation could alter the existing `eval(srepr(expr)) == expr`
expectation for SymPy container objects.
