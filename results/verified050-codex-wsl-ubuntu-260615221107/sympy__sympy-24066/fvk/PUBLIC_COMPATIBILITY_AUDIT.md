# Public Compatibility Audit

Status: static inspection only.

Changed public symbols: none.

Changed private/internal symbols:

- Added `UnitSystem._is_dimensionless(self, dimension)`.
- Added `UnitSystem._dimensions_equivalent(self, dim1, dim2)`.
- Updated internal calls in `UnitSystem._collect_factor_and_dimension()`.

Public method signature:

- `UnitSystem._collect_factor_and_dimension(self, expr)` is unchanged.

Return shape:

- Existing one-argument function branch still returns a two-item tuple
  `(factor, dimension)`.
- The reported dimensionless function path now returns `Dimension(1)` instead of
  the raw equivalent derived dimension.

Compatibility conclusion:

No public callsite or subclass override changes are required. Existing
incompatible-addition behavior is preserved by `_dimensions_equivalent()` returning
false when dimensions are not equivalent or cannot be analyzed.
