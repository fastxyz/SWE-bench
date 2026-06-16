# Proof Obligations

Status: discharged by source inspection and constructed K claims, not
machine-checked.

## PO-001: No `StopIteration` escapes for all-nonfinite representatives

- Intent: E-001, E-004, E-006.
- Code path: `_convert_dx` representative selection for `x0` and `xconv`.
- Obligation: if `_safe_first_finite` raises `StopIteration` because no finite
  element exists, `_convert_dx` must select `safe_first_element` and continue.
- Discharge: V1 has explicit `except StopIteration` branches for both `x0` and
  `xconv`.
- K claim: `ALL_NONFINITE_NO_STOP`.

## PO-002: The concrete reproduction produces nonfinite conversion data

- Intent: E-002, E-003.
- Input class: scalar `dx`, `x0 = [nan]`, `xconv = [nan]`.
- Obligation: representative selection returns `nan` for both original and
  converted coordinates; the scalar conversion path returns one nonfinite width
  value instead of an exception.
- Discharge: `safe_first_element([nan])` returns `nan` in both branches, and the
  scalar delist path is unchanged.
- K claim: `REPRO_SINGLE_NAN`.

## PO-003: Mixed leading-NaN data still uses first finite values

- Intent: E-005.
- Input class: sequences with a leading `nan` and at least one later finite
  element.
- Obligation: `_convert_dx` must continue to use `_safe_first_finite` when it
  succeeds.
- Discharge: V1 catches only `StopIteration`; successful first-finite selection
  is unchanged.
- K claim: `MIXED_LEADING_NAN_KEEPS_FIRST_FINITE`.

## PO-004: Empty converted x data remains unchanged

- Intent: E-008, E-009.
- Input class: `xconv.size == 0`.
- Obligation: `_convert_dx` returns `convert(dx)` without representative
  selection.
- Discharge: V1 does not edit the early empty branch.
- K claim: `EMPTY_XCONV_UNCHANGED`.

## PO-005: Conversion-error fallback remains unchanged

- Intent: E-010.
- Input class: selected representative or delta conversion raises
  `ValueError`, `TypeError`, or `AttributeError`.
- Obligation: `_convert_dx` still falls back to `convert(dx)`.
- Discharge: V1 only adds inner `StopIteration` handlers and leaves the outer
  fallback tuple unchanged.
- K claim: frame condition in `convert-dx-spec.k`; inspected in source.

## PO-006: Scalar versus iterable `dx` shape is preserved

- Intent: implementation contract and public compatibility.
- Input class: scalar `dx` and iterable `dx`.
- Obligation: scalar `dx` returns one scalar result after delisting; iterable
  `dx` returns elementwise conversion data.
- Discharge: V1 does not edit the `delist` logic.
- K claim: shape captured by `mapDelta` over `Dxs`; scalar case in
  `REPRO_SINGLE_NAN`.

## PO-007: No public API or global helper behavior changes

- Intent: E-006, E-011, E-012.
- Input/callsite class: public `Axes.bar`/`barh` and internal `_convert_dx`
  callers.
- Obligation: fix the local conversion path without changing public signatures
  or global `cbook._safe_first_finite` semantics.
- Discharge: only `repo/lib/matplotlib/axes/_axes.py` is changed; the helper
  signature is unchanged; `cbook` is untouched.
- K claim: frame condition; compatibility audit pass.
