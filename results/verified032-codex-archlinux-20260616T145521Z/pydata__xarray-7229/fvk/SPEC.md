# FVK Specification: `xr.where(..., keep_attrs=True)`

Status: constructed from public intent and source inspection; not machine-checked.

## Scope

Target function: `xarray.core.computation.where(cond, x, y, keep_attrs=None)`.

Audited branch: `keep_attrs is True`, including `keep_attrs=None` only when the
global option resolves to true. The non-true branch is a frame condition: it
must continue to call `apply_ufunc(duck_array_ops.where, cond, x, y, ...)` with
the user-supplied attrs strategy.

## Intent-Only Obligations

- I1: `xr.where` computes values from `x` where `cond` is true and from `y`
  otherwise.
- I2: For `keep_attrs=True`, result object attrs are the attrs of `x`, the
  second public argument.
- I3: Coordinate attrs are coordinate-specific metadata and must be preserved;
  they must not be overwritten by data-variable attrs from `x`.
- I4: Scalar `x` has no attrs, so `xr.where(cond, scalar_x, y, keep_attrs=True)`
  must not accidentally copy attrs from `cond` or `y`.
- I5: For Dataset results, each data variable's attrs should follow the
  corresponding variable in Dataset `x`; if `x` is a non-Dataset object with
  attrs, those attrs are the only public source to apply to each result data
  variable.
- I6: Public API compatibility must be preserved: no signature change, no test
  edits, no new required callsite arguments.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem | "`xr.where(..., keep_attrs=True)` overwrites coordinate attributes" | Coordinate attrs are observable and must not be replaced by unrelated attrs. | Encoded by I3 / O4 |
| E2 | problem | "Coordinate attributes should be preserved." | Coordinate attr frame condition. | Encoded by I3 / O4 |
| E3 | problem MVCE | `xr.where(True, ds.air, ds.air, keep_attrs=True).time.attrs` should be `{'standard_name': 'time', 'long_name': 'Time'}` | For a scalar condition and DataArray `x`, `time` attrs remain coordinate attrs. | Encoded by O4 |
| E4 | `where` docstring | "`keep_attrs`: If True, keep the attrs of `x`." | Result attrs come from public argument `x`, not from `cond` or `y`. | Encoded by I2 / O2 |
| E5 | `where` comment | "consistent with the `where` method of `DataArray` and `Dataset`" | Public function should use the same attrs winner as the methods: the data object (`x` / caller), not the condition. | Encoded by O2-O4 |
| E6 | public hint | "`attrs[1]` ... if `x` is a scalar ... ends up being the attrs of `y`" | Fix must not regress scalar-`x` behavior by indexing filtered attrs lists. | Encoded by I4 / O5 |
| E7 | implementation | `apply_dataarray_vfunc` sends `keep_attrs` to `build_output_coords_and_indexes` for coordinate merging. | A callable returning `x.attrs` is too broad because it also controls coordinate attrs. | Finding F1, resolved |
| E8 | implementation | `ops.where_method(self, cond, other)` calls `apply_ufunc(..., self, cond, other, keep_attrs=True)`. | `x`-first dispatch is the method-compatible ordering for attrs and coordinate merge. | Encoded by O2-O4 |

## Abstract Model

The formal model abstracts away array element computation except for preserving
the value operation's argument order. Each labeled object is modeled as:

- `value(o)`: data payload;
- `attrs(o)`: top-level/DataArray attrs, empty for scalars;
- `coordAttrs(o, c)`: attrs of coordinate `c`, when present;
- `dataVarAttrs(o, v)`: attrs of Dataset data variable `v`, when present.

For `where(cond, x, y, keep_attrs=True)`, the required result is:

- `value(result) = whereValue(cond, x, y)`;
- `attrs(result) = attrs(x)` when the result type supports attrs;
- for Dataset result data variable `v`:
  - `attrs(result[v]) = dataVarAttrs(x, v)` if `x` is a Dataset and contains
    `v`;
  - otherwise `attrs(result[v]) = attrs(x)`;
- for coordinate `c`, coordinate merging uses the normal `keep_attrs=True`
  override strategy with public priority `x`, then `cond`, then `y`, so
  `coordAttrs(result, c)` is the first available coordinate attrs in that order;
- if `x` is scalar/unlabeled, `attrs(x) = {}`.

This abstraction keeps the property under verification observable: the model
distinguishes data attrs from coordinate attrs and distinguishes scalar `x` from
labeled `x`.

## Formal Claim Paraphrases

- C1: Calling the V1 `keep_attrs=True` branch with symbolic `COND`, `X`, and `Y`
  reaches a result whose values are computed as `duck_array_ops.where(COND, X, Y)`.
- C2: The same execution reaches a result whose top attrs are exactly
  `attrs(X)`.
- C3: If the result is a Dataset, every result data variable's attrs are copied
  from the matching data variable in Dataset `X`, or from `attrs(X)` when `X` is
  not a Dataset.
- C4: Every result coordinate keeps coordinate attrs from the coordinate merge
  winner; data attrs from `X` are never used as coordinate attrs merely because
  `keep_attrs=True`.
- C5: If `X` is scalar/unlabeled, `attrs(X)` is empty, so no attrs from `COND`
  or `Y` are copied into result attrs by the keep-attrs branch.

Adequacy audit: C1-C5 are exactly I1-I5. No formal claim preserves legacy
coordinate-overwrite behavior. No public compatibility obligation is ambiguous:
the function signature and non-true branch are unchanged.

