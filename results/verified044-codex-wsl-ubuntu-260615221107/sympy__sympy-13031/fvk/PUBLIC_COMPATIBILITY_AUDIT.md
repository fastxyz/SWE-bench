# Public Compatibility Audit

## Changed Symbols

- `MutableSparseMatrix.col_join(self, other)` in
  `repo/sympy/matrices/sparse.py`.
- `MutableSparseMatrix.row_join(self, other)` in
  `repo/sympy/matrices/sparse.py`.

## API Shape

- Signatures are unchanged.
- Return path remains sparse-specific: `A.copy()` returns `self._new(...)`,
  and public `SparseMatrix` is an alias of `MutableSparseMatrix`.
- No new keyword arguments, no changed call protocol, and no changed public
  constructor format.

## Public Callers and Dispatch

- `MatrixShaping.hstack` reduces through `type(args[0]).row_join`.
- `MatrixShaping.vstack` reduces through `type(args[0]).col_join`.
- Because public `sympy.matrices.SparseMatrix` aliases `MutableSparseMatrix`,
  the changed methods are the dispatch target for the issue's examples.
- Existing dense `MatrixShaping.row_join` and `MatrixShaping.col_join` are not
  modified.
- `ImmutableSparseMatrix` is not the public alias used by the issue. It inherits
  the generic path and is outside the modified sparse override.

## Compatibility Result

Pass. V1 changes behavior only where the previous sparse override contradicted
the public null-matrix shape rules; it does not introduce a signature or dispatch
compatibility break.
