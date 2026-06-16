# Public Compatibility Audit

Status: constructed from source inspection only; no code was run.

Changed public symbol: none.

Changed private helper: `_ensure_numeric` in `repo/xarray/core/computation.py`.

Compatibility checks:

PC1. `polyval` signature is unchanged. Existing overloads still accept
`DataArray` and `Dataset` combinations and keep `degree_dim="degree"`.

PC2. Degree coordinate validation is unchanged. The checks for a labeled integer
degree coordinate still run before numericization.

PC3. Existing datetime behavior is preserved by the separate `x.dtype.kind == "M"`
branch using the original `np.datetime64("1970-01-01")` offset.

PC4. Existing numeric behavior is preserved because non-`m`/`M` inputs still
return unchanged from `to_floatable`.

PC5. Dataset behavior remains mapped through `Dataset.map(to_floatable)`, matching
the previous structure. No caller or override signature changed.

PC6. No test files or public test expectations were edited.
