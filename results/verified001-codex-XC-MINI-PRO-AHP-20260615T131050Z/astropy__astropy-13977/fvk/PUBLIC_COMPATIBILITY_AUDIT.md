# Public Compatibility Audit

Changed public symbol: `astropy.units.Quantity.__array_ufunc__`.

Signature: unchanged.

Return shape: unchanged for existing Quantity/ndarray paths; new early
`NotImplemented` for unrecognized unit-bearing objects.

Public callsites and overrides:

- `FunctionQuantity.__array_ufunc__` calls `super().__array_ufunc__` for
  supported function ufuncs. It still reaches the V1 guard for those supported
  paths. Its unsupported-ufunc `UnitTypeError` policy is unchanged.
- `SpecificTypeQuantity` does not override `__array_ufunc__`; it inherits the
  V1 guard.
- Astropy table `BaseColumn` subclasses `numpy.ndarray`, so Column and
  MaskedColumn instances are accepted by the V1 guard.

Compatibility conclusion: no public signature or recognized-object compatibility
break was found. The intentional behavior change is limited to non-recognized
unit-bearing objects, matching the public issue and hint.

