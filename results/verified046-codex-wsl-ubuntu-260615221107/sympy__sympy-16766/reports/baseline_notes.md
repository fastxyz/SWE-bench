# Baseline Notes

## Root cause

`PythonCodePrinter` did not define a printer method for `Indexed`. Since
`Indexed` is an `Expr`, the generic `CodePrinter._print_Expr` path treated it
as unsupported, recorded it in `_not_supported`, and then fell back to the
string representation. That produced valid-looking code such as `p[0]`, but
with the "Not supported in Python: Indexed" preamble.

The same dispatch behavior also applies to `Idx`, which is commonly used as an
index in `Indexed` expressions. Printing `Indexed` by recursively printing its
indices therefore also needs a Python printer for `Idx`.

## Files changed

`repo/sympy/printing/pycode.py`

- Added `PythonCodePrinter._print_Indexed` so Python code generation emits
  native subscript syntax like `p[0]` or `A[i, j]` without registering the
  expression as unsupported.
- Added `PythonCodePrinter._print_Idx` so symbolic `Idx` objects used inside
  `Indexed` expressions print as their labels instead of going through the
  generic unsupported `Expr` path.

## Assumptions

- Python code generation should preserve multidimensional indexed expressions
  with comma-separated Python subscript syntax rather than flattening them to a
  one-dimensional storage offset. That matches the issue hint and is appropriate
  for Python objects such as NumPy arrays that accept tuple-style indexing.
- For an `IndexedBase`, the code printer should print the base label through
  `self._print` instead of using raw `str()`, so normal Python symbol handling
  such as reserved-word suffixing still applies.
- I did not run tests or project code, per the task instructions.

## Alternatives considered

- Adding only `_print_Indexed` was rejected because recursively printing an
  `Idx` index would still mark `Idx` as unsupported.
- Reusing the C or JavaScript printer's flattened indexing logic was rejected
  because Python syntax naturally supports multidimensional subscripts and the
  issue explicitly requested output like `p[0]`.
- Adding the implementation to `AbstractPythonCodePrinter` was rejected to keep
  the change focused on `PythonCodePrinter` and its existing Python-code
  subclasses, without changing unrelated printers that inherit directly from
  the abstract base.
