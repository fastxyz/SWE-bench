# FVK Spec

Status: constructed, not machine-checked. Scope is the issue-relevant
`polyval`/`_ensure_numeric` behavior, not the entire xarray library.

## Target

Files inspected:

- `repo/xarray/core/computation.py`
- `repo/xarray/core/duck_array_ops.py`
- `repo/xarray/core/missing.py`
- `benchmark/PROBLEM.md`
- `reports/baseline_notes.md`

Source lines of interest:

- `polyval` validates degree coordinates, reindexes missing degrees to zero,
  then calls `_ensure_numeric` before Horner evaluation:
  `repo/xarray/core/computation.py:1896-1917`.
- `_ensure_numeric` now separates `datetime64` (`kind == "M"`) from
  `timedelta64` (`kind == "m"`):
  `repo/xarray/core/computation.py:1920-1957`.
- `datetime_to_numeric` subtracts the supplied offset, divides by the requested
  time unit, and maps NaT to NaN:
  `repo/xarray/core/duck_array_ops.py:398-450`.
- `polyfit` obtains x values through `get_clean_interp_index`; datetime indexes
  are special-cased to epoch nanoseconds, while timedelta indexes fall through to
  raw float values:
  `repo/xarray/core/missing.py:275-288`.

## Public Intent Ledger

The ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

E1. The issue title says "`polyval` with timedelta64 coordinates produces wrong
results". Obligation: timedelta coordinate values must be a supported `polyval`
input class.

E2. The public hint says the new implementation uses the values of `coord`, not
the index coordinate. Obligation: do not restore the old behavior of reading the
index coordinate when the `coord` argument's data are datetime values.

E3. The public hint says `azimuth_time.coords["azimuth_time"]` "should work, so
this is a bug". Obligation: a `DataArray` coordinate with dtype kind `m` must
convert successfully and feed Horner evaluation.

E4. The reported traceback shows a failed subtraction between `timedelta64` and
`datetime64`. Obligation: timedelta conversion must not pass a datetime epoch
offset into `datetime_to_numeric`.

E5. The `polyval` docstring says `coord` contains the values at which to
evaluate the polynomial. Obligation: the numericized `coord` values are the x
values used by Horner evaluation.

E6. Existing interpolation/polyfit support defines datetime numeric values as
nanoseconds relative to 1970-01-01. Obligation: preserve existing datetime
behavior.

E7. Existing `polyfit` support converts non-datetime indexes, including
timedelta indexes, to raw float values. Obligation: timedelta `polyval` values
should be durations in nanoseconds from zero, not relative to their minimum.

E8. The public signature accepts `DataArray` and `Dataset`. Obligation: do not
broaden the repair to plain NumPy arrays unless separately requested.

## Intended Contract

For every `DataArray` or `Dataset` coordinate variable passed to `polyval`:

- If the variable dtype is `datetime64`, convert its data to float nanoseconds
  relative to 1970-01-01.
- If the variable dtype is `timedelta64`, convert its data to float nanoseconds
  relative to zero duration.
- If the variable dtype is not datetime-like, leave its data unchanged.
- Preserve the existing missing-value conversion of datetime-like NaT to NaN.
- Then evaluate the polynomial by Horner's method over the numericized coord
  values and degree-labeled coefficients, with absent degrees reindexed to zero.

## Formal Core

The formal core is split into:

- `fvk/mini-xarray-polyval.k`: a mini semantics for dtype-dispatched coordinate
  numericization and Horner-style polynomial evaluation.
- `fvk/polyval-spec.k`: reachability claims for datetime, timedelta, numeric,
  missing-value, and polynomial-evaluation behavior.

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-xarray-polyval.k --backend haskell
kast --backend haskell fvk/polyval-spec.k
kprove fvk/polyval-spec.k
```

## Adequacy

The adequacy round trip is recorded in:

- `fvk/INTENT_SPEC.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

All required clauses pass the adequacy audit. The two ambiguous points are
resolved as scope constraints: the original `DataArray`-with-datetime-data call
is governed by the new "coord values" contract, and the NumPy-array workaround is
outside the public signature.

## Decision

V1 stands unchanged. Its `timedelta64` branch satisfies the direct public bug
obligation, its `datetime64` branch preserves existing behavior, and its zero
timedelta offset is necessary to match `polyfit`'s raw timedelta numeric domain.
