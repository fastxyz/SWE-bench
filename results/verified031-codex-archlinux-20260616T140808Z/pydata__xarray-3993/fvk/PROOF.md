# FVK Proof

Status: constructed, not machine-checked. The benchmark forbids running tests, Python, `kompile`, `kast`, or `kprove`.

## Claims Proved Constructively

The proof covers the public API normalization layer for `DataArray.integrate`.

DATAARRAY-INTEGRATE-COORD: a call using `coord=C` reaches delegation to `Dataset.integrate(C, U)`.

DATAARRAY-INTEGRATE-POSITIONAL: a positional call with first argument `C` reaches delegation to `Dataset.integrate(C, U)`.

DATAARRAY-INTEGRATE-DIM-ALIAS: a legacy `dim=D` call reaches a warning-plus-delegation outcome using `D` as the coordinate.

DATAARRAY-INTEGRATE-BOTH-NAMES: a call that supplies both names reaches the duplicate-name `TypeError` outcome.

DATAARRAY-INTEGRATE-UNEXPECTED-KEYWORD: a call with an unrelated keyword remains an unexpected-keyword error.

## Source-Level Proof Sketch

1. The public intent requires the operand name `coord`. V1 changes the wrapped method signature from `dim` to `coord`, satisfying PO-001.

2. For the `coord=` and positional paths, `_deprecate_dataarray_integrate_dim` does not modify `args` or `kwargs` because no `dim` key is present. Control reaches the wrapped method with the original coordinate and `datetime_unit`. The wrapped method delegates via `self._to_temp_dataset().integrate(coord, datetime_unit)`, satisfying PO-002 and PO-003.

3. For the legacy `dim=` path, the wrapper sees `"dim" in kwargs`, checks that no positional coordinate and no `coord` keyword were also supplied, emits a `FutureWarning`, moves the value to `kwargs["coord"]`, removes `dim`, and calls the wrapped method. The wrapped method then follows the same delegation path as PO-002. This discharges PO-004.

4. For duplicate names, the wrapper detects `dim` plus either positional args or `coord` and raises `TypeError` before delegation. This prevents an ambiguous coordinate choice and discharges PO-005.

5. For unrelated unexpected keywords, the wrapper has no matching special case and calls the wrapped method. Since the wrapped method signature accepts only `coord` and `datetime_unit`, normal Python call binding rejects the extra keyword. This discharges PO-007.

6. The numerical implementation remains in `Dataset.integrate` and `_integrate_one`; V1 does not edit those functions. All non-error normalized paths delegate to `Dataset.integrate` with the same coordinate and unit. This establishes the frame condition PO-006.

## Machine-Check Commands Not Run

These are the commands to run later in an environment with K installed:

```sh
kompile fvk/mini-python-api.k --backend haskell
kast --backend haskell fvk/dataarray-integrate-spec.k
kprove fvk/dataarray-integrate-spec.k
```

Expected result after machine checking: `#Top` for the listed claims. This expectation is constructed from source reasoning and has not been observed.

## Test Guidance

Keep all existing tests. Do not remove tests based on this constructed proof.

Recommended additional public tests after this audit:

- `DataArray.integrate(coord="x")` delegates equivalently to `Dataset.integrate("x")`.
- `DataArray.integrate(dim="x")` works with a `FutureWarning`.
- Supplying both `coord` and `dim` raises `TypeError`.
- Signature/introspection exposes `coord` rather than `dim`.

## Residual Risk

The proof is partial and constructed, not machine-checked. It verifies the API argument-normalization layer and frames the unchanged numerical integration implementation; it does not re-prove trapezoidal arithmetic, dask behavior, datetime conversion, or all xarray object invariants.
