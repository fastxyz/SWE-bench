# Baseline notes — pydata__xarray-3993

## Issue summary

The integration/differentiation API was inconsistent:

```python
ds.differentiate(coord='x')   # coord
da.differentiate(coord='x')   # coord
ds.integrate(coord='x')       # coord
da.integrate(dim='x')         # dim  ← the odd one out
```

`DataArray.integrate` was the only one of the four methods that named its
primary argument `dim` instead of `coord`. The argument is in fact a
*coordinate* (you integrate "with respect to" a coordinate, using the spacing
between its values), so `coord` is the correct, consistent name. The reporter
explicitly raised the question of whether a deprecation cycle is required — and
since `DataArray.integrate(dim=...)` is part of a released public API, simply
renaming the parameter would break existing user code. The fix therefore
introduces `coord` while keeping `dim` working for one deprecation cycle with a
`FutureWarning`.

## Root cause

`DataArray.integrate` (in `xarray/core/dataarray.py`) was defined as:

```python
def integrate(self, dim, datetime_unit=None) -> "DataArray":
    ...
    ds = self._to_temp_dataset().integrate(dim, datetime_unit)
    return self._from_temp_dataset(ds)
```

It delegated to `Dataset.integrate(self, coord, datetime_unit=None)`, which
already uses `coord`. So only the *DataArray* wrapper used the wrong name; the
underlying implementation was already coordinate-based. No numerical/behavioral
bug — purely an API naming inconsistency in one public method's signature and
docstring.

## Changes

### `repo/xarray/core/dataarray.py` — `DataArray.integrate`
- Renamed the primary parameter `dim` → `coord` and gave it a default of
  `None`, matching `DataArray.differentiate`, `Dataset.differentiate`, and
  `Dataset.integrate`.
- Added a keyword-only, deprecated `dim` parameter (also defaulting to `None`).
- Added handling at the top of the body:
  - If both `dim` and `coord` are given → `ValueError` (ambiguous).
  - If only `dim` is given → copy it into `coord` and emit a `FutureWarning`
    pointing users at `coord`.
- The delegation now passes `coord` to `Dataset.integrate`.
- Updated the docstring: documents `coord`, marks `dim` as
  `.. deprecated:: 0.17.0`, fixes the `.. note::` text (`dim` → `coord`), and
  adds a `Dataset.integrate` cross-reference under "See also".

`warnings` and the `Union`/`Hashable`/`Sequence` typing names were already
imported at the top of the module, so no new imports were needed.

### `repo/doc/whats-new.rst`
- Added a "Deprecations" section under the unreleased v0.17.0 entry describing
  the `dim` → `coord` deprecation for `DataArray.integrate`.

## Why this preserves backward compatibility

The previous signature was `integrate(self, dim, datetime_unit=None)`. The new
signature is `integrate(self, coord=None, datetime_unit=None, *, dim=None)`.

- `da.integrate("x")` → binds to `coord` (positional). Same result as before,
  no warning. (This is how the existing visible tests and the docs call it.)
- `da.integrate("x", "D")` / `da.integrate("time", datetime_unit="D")` →
  `coord="time"`, `datetime_unit="D"`. Unchanged.
- `da.integrate(("y", "x"))` → sequence still accepted (forwarded to
  `Dataset.integrate`, which loops over the entries). Unchanged.
- `da.integrate(dim="x")` → still works, but now emits a `FutureWarning` and is
  internally mapped to `coord`.
- `da.integrate(coord="x", dim="x")` → `ValueError` (ambiguous), which is the
  desired behavior for a mutually-exclusive alias.

Making `dim` keyword-only (after `*`) means no positional call site can
accidentally bind a third positional argument to it, and it keeps the public,
recommended positional argument unambiguously `coord`.

## Assumptions and rejected alternatives

- **Deprecation cycle vs. hard rename.** The reporter asked whether a
  deprecation cycle is needed. I assumed yes: `dim` is a released public kwarg,
  so removing it outright would be a breaking change. A `FutureWarning` (the
  convention used elsewhere in xarray, e.g. `rolling.py`, `computation.py`) is
  shown to users by default and preserves their working code, so it is the
  responsible choice. Rejected: hard-removing `dim` (breaks users) and a silent
  alias with no warning (never lets the deprecation actually complete).

- **Only `DataArray.integrate` needs changing.** `Dataset.integrate`,
  `Dataset.differentiate`, and `DataArray.differentiate` already use `coord`,
  so I left them untouched to keep the change minimal and targeted. I verified
  via grep that the only `dim`-named integrate API was the DataArray wrapper.

- **`dim` placement.** I considered leaving `dim` as a normal (non-keyword-only)
  parameter, but that would allow odd positional calls and muddy which argument
  is canonical. Keyword-only `dim` is cleaner and still satisfies every
  realistic legacy call (`da.integrate(dim=...)`).

- **Warning category.** Chose `FutureWarning` (visible to end users by default)
  over `DeprecationWarning` (hidden by default in library code), matching the
  existing xarray deprecation pattern, so users actually see the notice.

- **Internal/doc call sites.** Searched the repo: the only internal call is the
  delegation inside `DataArray.integrate` itself (updated), and the docs/visible
  tests use positional `integrate("x")`, which is unaffected. I did not modify
  any test files (per task constraints).
