# FVK Spec: pydata__xarray-3993

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The audited unit is the public `DataArray.integrate` API in `repo/xarray/core/dataarray.py`. The numerical trapezoid implementation is delegated to `Dataset.integrate` and `Dataset._integrate_one`; V1 did not change that implementation, so this spec focuses on the public argument name, keyword compatibility, and delegation frame condition.

## Intent-Only Requirements

I-001: `DataArray.integrate` must expose `coord`, not `dim`, as the coordinate argument.

I-002: Passing `coord=` to `DataArray.integrate` must be accepted and must delegate to `Dataset.integrate` with the same coordinate value and `datetime_unit`.

I-003: Existing positional calls such as `da.integrate("x")` must continue to delegate unchanged.

I-004: The old `dim=` keyword has public compatibility evidence and should not be removed abruptly; it may be retained as a deprecated alias.

I-005: Supplying both `coord` and `dim` is invalid because it gives two names for the same semantic operand.

I-006: Numerical integration semantics, coordinate validation, multidimensional-coordinate rejection, datetime-unit behavior, coordinate dropping, and dask preservation are frame conditions owned by `Dataset.integrate` and must remain unchanged by this API rename.

## Public Evidence Ledger

E-001, prompt: "DataArray.integrate has a 'dim' arg, but Dataset.integrate has a 'coord' arg" gives the mismatch to remove. Status: encoded by PO-001 and PO-002.

E-002, prompt: "It should definitely be `coord`" gives the required public name. Status: encoded by PO-001.

E-003, prompt: "it doesn't make sense to integrate or differentiate over a dim because a dim by definition has no information about the distance between grid points" gives the semantic reason: the operand is a coordinate. Status: encoded by PO-002 and PO-006.

E-004, prompt: "The only question is whether it requires a deprecation cycle?" makes abrupt removal of `dim=` ambiguous and licenses a compatibility/deprecation path. Status: encoded by PO-004.

E-005, code: `Dataset.integrate(self, coord, datetime_unit=None)` already uses `coord` and performs the shared implementation. Status: frame condition PO-006.

E-006, public tests: `repo/xarray/tests/test_units.py` has `method("integrate", dim="x")`. This is legacy behavior, but because it does not contradict the prompt if treated as a deprecated compatibility path, it supports PO-004. Status: compatibility evidence, not a veto against the new `coord` API.

E-007, public docs/tests: `repo/doc/computation.rst` and integration tests use positional `a.integrate("x")` / `da.integrate("x")`. Status: encoded by PO-003.

## Formal Model

The formal core is in:

- `fvk/mini-python-api.k`
- `fvk/dataarray-integrate-spec.k`

The model abstracts the full Python method body into API call classes that preserve the property under audit: visible operand name, deprecated alias behavior, error on duplicate names, and delegated coordinate value. It intentionally abstracts away array contents and trapezoid arithmetic because V1 does not alter them and PO-006 frames that behavior through `Dataset.integrate`.

## Formal Spec English

K-001: A call represented as `integrateCoord(C, U)` reaches `delegateDatasetIntegrate(C, U)`.

K-002: A call represented as `integratePositional(C, U)` reaches `delegateDatasetIntegrate(C, U)`.

K-003: A call represented as `integrateDim(D, U)` reaches `warnDelegateDatasetIntegrate(D, U)`.

K-004: A call represented as `integrateBoth(C, D, U)` reaches `typeError("cannot specify both 'coord' and 'dim'")`.

K-005: A call represented as `integrateUnexpected(K)` reaches `typeError("unexpected keyword")`.

## Adequacy Audit

K-001 passes I-001 and I-002: the formal claim uses `coord` and preserves the delegated coordinate.

K-002 passes I-003: positional calls preserve the coordinate and unit.

K-003 passes I-004: the formal claim does not preserve `dim` as the public name; it models it as a warning-producing compatibility alias.

K-004 passes I-005: duplicate names are rejected.

K-005 passes Python default API behavior and does not add a new requirement beyond preserving unexpected-keyword errors.

PO-006 is a frame condition, not a mini-K arithmetic proof. It is justified by the source-level proof that V1 still calls `self._to_temp_dataset().integrate(coord, datetime_unit)` and did not edit `Dataset.integrate` or `Dataset._integrate_one`.

## Public Compatibility Audit

Changed public symbol: `DataArray.integrate`.

Callsites found by `rg`: public docs and tests use positional calls; one public units test helper uses `dim="x"`. V1 preserves both classes. No in-repo subclasses override `integrate`; the only direct `DataArray` subclass occurrence in tests checks `__slots__` behavior and does not override this method.

Warning policy: `repo/setup.cfg` does not turn `FutureWarning` into an error globally. `repo/xarray/tests/test_units.py` only promotes `pint.UnitStrippedWarning`, so the compatibility warning is not contradicted by local public warning configuration.

Conclusion: V1 satisfies the compatibility audit.
