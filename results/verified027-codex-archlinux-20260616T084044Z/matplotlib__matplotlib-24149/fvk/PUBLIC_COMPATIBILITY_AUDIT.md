# Public Compatibility Audit

Status: pass.

## Changed Symbol

`Axes._convert_dx(dx, x0, xconv, convert)` in
`repo/lib/matplotlib/axes/_axes.py`.

- Visibility: private static helper.
- Signature: unchanged.
- Return shape: unchanged by branch class. Empty `xconv` still returns
  `convert(dx)`. Scalar `dx` still delists to a scalar. Iterable `dx` still maps
  elementwise.
- Exception policy: existing `ValueError`/`TypeError`/`AttributeError` fallback
  is unchanged. V1 only handles `StopIteration` from representative selection.

## Public Observable Callers

- `Axes.bar`: calls `_convert_dx` for `width`, `xerr`, `height`, and `yerr`.
  The public issue reaches the width call after x-unit conversion.
- `Axes.barh`: delegates into `bar`, so it observes the same helper behavior.
- `Axes.broken_barh`: calls `_convert_dx` for converted x ranges.

## Compatibility Findings

No public method signature, keyword, return container type, or subclass override
protocol changes. The helper remains private and all callers continue passing
the same four arguments.

The narrower alternative, changing only `Axes.bar`, would leave other
`_convert_dx` callers with the same all-nonfinite representative-selection
hazard. The broader alternative, changing `cbook._safe_first_finite`, would
affect unrelated callers that already treat `StopIteration` as meaningful.
