# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Public Signature Uses `coord`

Requirement: the visible `DataArray.integrate` API must name the coordinate operand `coord`.

Evidence: prompt E-001 to E-003.

Discharge: V1 changes the wrapped method definition to `def integrate(self, coord, datetime_unit=None)`. The compatibility wrapper uses `functools.wraps`, preserving the wrapped function metadata for documentation and signature introspection.

Status: discharged by source audit.

## PO-002: `coord=` Delegates the Same Operand

Requirement: `da.integrate(coord=C, datetime_unit=U)` must call `Dataset.integrate(C, U)` and return `_from_temp_dataset` of that result.

Evidence: prompt E-002/E-003 and dataset implementation E-005.

Discharge: V1 body calls `self._to_temp_dataset().integrate(coord, datetime_unit)`.

Formal claim: DATAARRAY-INTEGRATE-COORD in `fvk/dataarray-integrate-spec.k`.

Status: discharged by source audit and constructed formal claim.

## PO-003: Positional Calls Are Preserved

Requirement: `da.integrate(C, U)` must keep working as before.

Evidence: public docs/tests E-007.

Discharge: the wrapped function still accepts `coord` as the first positional argument and delegates it unchanged.

Formal claim: DATAARRAY-INTEGRATE-POSITIONAL.

Status: discharged by source audit and constructed formal claim.

## PO-004: Deprecated `dim=` Alias Is Preserved

Requirement: `da.integrate(dim=D, datetime_unit=U)` must not break abruptly; it should normalize to `coord=D` while signaling deprecation.

Evidence: prompt E-004 and public test helper E-006.

Discharge: `_deprecate_dataarray_integrate_dim` detects `dim`, emits `FutureWarning`, assigns `kwargs["coord"] = kwargs.pop("dim")`, and calls the wrapped method.

Formal claim: DATAARRAY-INTEGRATE-DIM-ALIAS.

Status: discharged by source audit and constructed formal claim.

## PO-005: Duplicate `coord` and `dim` Are Rejected

Requirement: calls specifying both names for the same coordinate operand must fail rather than silently choosing one.

Evidence: API consistency default-domain assumption.

Discharge: the wrapper raises `TypeError` when `dim` is present and either positional args or `coord` are also present.

Formal claim: DATAARRAY-INTEGRATE-BOTH-NAMES.

Status: discharged by source audit and constructed formal claim.

## PO-006: Numerical Behavior Is Framed

Requirement: V1 must not alter trapezoidal integration arithmetic, datetime-unit conversion, coordinate validation, multidimensional-coordinate rejection, coordinate dropping, dask preservation, or output reconstruction.

Evidence: prompt scope plus source E-005.

Discharge: V1 edits only `DataArray.integrate` API naming and a wrapper. It does not edit `Dataset.integrate`, `Dataset._integrate_one`, or downstream numerical operations. Every normalized path delegates to the same dataset method.

Status: discharged by source audit; not modeled in mini-K because it is an unchanged frame condition.

## PO-007: Unexpected Keywords Remain Errors

Requirement: adding the `dim` compatibility wrapper must not swallow unrelated unexpected keywords.

Evidence: Python method-call default-domain behavior and public API compatibility.

Discharge: the wrapper only handles `dim`; all other keywords are forwarded to the wrapped method, whose signature rejects unexpected keywords.

Formal claim: DATAARRAY-INTEGRATE-UNEXPECTED-KEYWORD.

Status: discharged by source audit and constructed formal claim.
