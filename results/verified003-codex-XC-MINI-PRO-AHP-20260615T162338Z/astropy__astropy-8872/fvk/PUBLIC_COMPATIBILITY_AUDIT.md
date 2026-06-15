# Public Compatibility Audit

Status: no public API incompatibility found.

## Changed Symbol

`astropy.units.quantity.Quantity.__new__`

- Signature changed: no.
- Return type changed: no. It remains a `Quantity` / subclass view according to
  the existing constructor rules.
- Public dispatch shape changed: no.
- Storage format changed: no. Only the default dtype-preservation predicate for
  inexact dtypes changed.

## Public Call Path

`astropy.units.core.UnitBase.__rmul__`

- Existing behavior: for numeric operands without a `unit` attribute, returns
  `Quantity(m, self)`.
- Compatibility status: unchanged. This path benefits from the constructor
  dtype fix without a caller change.

## Tests

No test files were modified. Public tests that assert explicit dtype,
integer-to-float default conversion, `float32` preservation, and object Decimal
coercion remain within the preserved frame conditions.

## Conclusion

No public caller, subclass override, or protocol consumer needs a change for
the V1 patch.
