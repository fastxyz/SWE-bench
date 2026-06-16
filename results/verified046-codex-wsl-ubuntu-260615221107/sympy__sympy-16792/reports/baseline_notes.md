# Baseline Notes

## Root cause

`CodeGen.routine` correctly marks matrix and indexed inputs as arrays when those
objects are present in the generated expressions. It builds `array_symbols` from
`Indexed` and `MatrixSymbol` atoms found in the expression and uses that table to
set `InputArgument.dimensions`.

When the user supplies an explicit `argument_sequence`, redundant arguments that
were not found in the expression are synthesized later with
`InputArgument(symbol)`. That path did not preserve array metadata. Therefore an
unused `MatrixSymbol` argument was treated as a scalar input, causing C code such
as `double x` instead of `double *x`. The Cython wrapper then passed a NumPy
array to a scalar C argument, producing the reported conversion error.

## Changed files

`repo/sympy/utilities/codegen.py`

Added `CodeGen._get_input_arg_metadata`, a small helper that derives dimensions
for array input arguments. Existing expression-derived inputs still use the same
metadata, but the logic is shared with the explicit redundant-argument path.

Updated `CodeGen.routine` so that when an explicit argument is not already in the
routine argument list, it creates the `InputArgument` with dimensions when the
symbol is a `MatrixSymbol`. The same path also preserves dimensions for an
explicit `IndexedBase` if that object carries shape information before it is
normalized to its label symbol.

## Assumptions and alternatives

I assumed that an explicit `MatrixSymbol` in `argument_sequence` should keep its
declared shape even if the expression does not reference it, because the public
API allows redundant arguments and the generated function signature is expected
to match the requested argument list.

I also assumed that an unused `IndexedBase` without shape information cannot be
reliably treated as an array, because there is no expression index or declared
shape from which to infer dimensions. In that case the previous scalar fallback
is left unchanged.

I considered fixing this in `autowrap` or the Cython wrapper, but rejected that
because the bad C signature is produced earlier by `codegen`. Preserving
dimensions in `Routine.arguments` fixes the root cause for C and Fortran code
generation, and lets Cython continue to consume the existing metadata.

I did not modify tests or run tests/project code, per the task constraints.
