# Baseline Notes

## Root Cause

`Quantity.__array_ufunc__()` accepted any input with a `unit` attribute as if it
were a Quantity-like object that Astropy knew how to convert. For binary ufuncs
such as addition, `converters_and_unit()` would therefore compute a converter for
an unrelated duck array that exposed `.unit`, and `Quantity.__array_ufunc__()`
would pass that duck array object into the converter before NumPy could dispatch
to the duck array's own reflected ufunc implementation. If the units differed,
the converter attempted numeric coercion of the duck object itself and raised
`ValueError` instead of returning `NotImplemented`.

## Changed Files

`repo/astropy/units/quantity.py`

Added an early guard in `Quantity.__array_ufunc__()` that returns
`NotImplemented` for non-`Quantity`, non-`numpy.ndarray` inputs or outputs that
have a `unit` attribute. This preserves the existing conversion path for
Quantities and ndarray subclasses, including table Columns, while letting
external unit-bearing duck arrays handle the ufunc themselves through NumPy's
dispatch protocol.

## Assumptions

The intended supported objects for Quantity-side unit conversion are Astropy
Quantities and ndarray subclasses. Table Columns remain supported because
`BaseColumn` is an ndarray subclass. Plain scalars and arrays without a `unit`
attribute remain on the existing code path.

I assumed that external objects with a `unit` attribute should not be coerced by
Astropy unless they are also ndarray-like. Returning `NotImplemented` lets NumPy
try their own `__array_ufunc__` implementation, matching the behavior requested
in the issue.

## Alternatives Considered

One alternative was to catch `ValueError` around converter application and return
`NotImplemented` only after conversion failed. I rejected that because it still
lets Astropy claim ownership of unknown unit-bearing duck arrays and only backs
out after partial coercion.

Another alternative was to change `converters_and_unit()` to ignore `.unit` for
unknown types. I rejected that because the dispatch decision belongs at the
`__array_ufunc__()` boundary, and changing the helper would risk altering lower
level unit logic shared by valid Quantity operations.
