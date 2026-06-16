# FVK Findings

Status: constructed, not machine-checked. Findings are based only on public issue text, source, docs, and public tests. No tests or code were run.

## F-001: Legacy API Name Mismatch, Resolved by V1

Input: `da.integrate(coord="x")`.

V0 observed from issue/code: `DataArray.integrate` exposed `dim`, so `coord=` was not the public DataArray keyword even though `Dataset.integrate` used `coord`.

Expected from public intent: `coord=` is the public keyword for `DataArray.integrate`, matching `Dataset.integrate` and both `differentiate` methods.

V1 status: resolved. The method signature is `integrate(self, coord, datetime_unit=None)`, and the body delegates that value to `Dataset.integrate`.

Related proof obligations: PO-001, PO-002.

## F-002: Backward Compatibility for `dim=`, Resolved by V1

Input: `da.integrate(dim="x")`.

Observed compatibility evidence: `repo/xarray/tests/test_units.py` contains a public helper call using `method("integrate", dim="x")`; the issue asks whether a deprecation cycle is required.

Expected from audit: the old keyword should remain accepted as a deprecated alias unless public intent clearly requires immediate removal.

V1 status: resolved. The wrapper translates `dim` to `coord` and emits a `FutureWarning`.

Related proof obligations: PO-004.

## F-003: Ambiguous Duplicate Names, Resolved by V1

Input: `da.integrate("x", dim="y")` or `da.integrate(coord="x", dim="y")`.

Observed risk: once `dim` is retained as an alias, callers can provide two values for the same coordinate operand.

Expected from API consistency: duplicate names must not silently choose one operand.

V1 status: resolved. The wrapper raises `TypeError("cannot specify both 'coord' and 'dim'")`.

Related proof obligations: PO-005.

## F-004: Numerical Integration Frame Condition, No V1 Regression Found

Input class: any in-domain `DataArray.integrate` call after argument normalization.

Observed risk: an API wrapper could accidentally change the coordinate value, `datetime_unit`, or integration implementation.

Expected from public intent: only the public argument name changes; trapezoid arithmetic and validation behavior stay owned by `Dataset.integrate`.

V1 status: no regression found by source audit. The delegated call remains `self._to_temp_dataset().integrate(coord, datetime_unit)`, and `Dataset.integrate` / `_integrate_one` were not modified.

Related proof obligations: PO-002, PO-003, PO-004, PO-006.

## F-005: Formal Tooling Not Executed, Residual Verification Caveat

Input: the emitted K artifacts and claims.

Observed limitation: the benchmark forbids running `kompile`, `kast`, or `kprove`.

Expected from FVK honesty gate: label the proof as constructed, not machine-checked; do not remove tests based on this proof alone.

V1 status: residual caveat documented in `PROOF.md` and `ITERATION_GUIDANCE.md`.

Related proof obligations: all proof obligations.
