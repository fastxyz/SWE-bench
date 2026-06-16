# FVK Findings

Status: constructed, not machine-checked.

## FVK-F1: Already-Dropped Comparison Attrs Cannot Be Recovered By `xr.where`

- Classification: residual limitation / separate public issue.
- Evidence: ledger E4 says `DataArray.__eq__` removes attrs by default and
  points to a separate attr-propagation issue.
- Input: `data` has attrs, `cond = data == 1`, `x = 5`, `y = 0`, with global
  `keep_attrs` at `"default"`.
- Observed by source reasoning: `cond` has no attrs, and neither scalar choice
  has attrs; `xr.where` has no remaining source from which to recover
  `data.attrs`.
- Expected if the broader comparison issue were solved: attrs would still be
  available on `cond`, or a data argument would carry them.
- Decision: no code change in this pass. The targeted `xr.where` wrapper fix
  preserves attrs when an attrs-bearing xarray object reaches `where`, and users
  can set `xr.set_options(keep_attrs=True)` before constructing `cond`.

## FVK-F2: Default Attr Preservation Is A Compatibility Risk But Intent-Supported

- Classification: compatibility risk, accepted.
- Evidence: E6 says hard-coding `keep_attrs=True` could be breaking; E2/E3/E7
  say attrs are expected to remain and method-level `where` already preserves
  them.
- Input: `xr.where(da == 0, -1, da)` where `da.attrs == {"foo": "bar"}`.
- V1 behavior by source reasoning: data-first attr order preserves `da.attrs`
  from `y` when `keep_attrs` resolves true.
- Alternative considered: default `keep_attrs=None` could be passed directly to
  `apply_ufunc`, preserving old default drop behavior. Rejected because it would
  leave the issue's explicit expected output failing unless users supplied a new
  keyword.
- Mitigation: V1 exposes `keep_attrs=False` and respects
  `xr.set_options(keep_attrs=False)`.

## FVK-F3: Value Semantics Are Preserved

- Classification: discharged proof obligation.
- Evidence: helper `_where_data_first(x, y, cond)` calls
  `duck_array_ops.where(cond, x, y)`.
- Input class: all exact-aligned in-domain inputs.
- Expected and V1 behavior: selected values remain `x` where `cond` is true and
  `y` otherwise.

## FVK-F4: No Public Callsite Or Override Break Was Found

- Classification: compatibility audit result.
- Evidence: public in-repository `xr.where` callsites use the existing
  three-argument form; `xr.where` is a top-level function with no override
  dispatch.
- Decision: adding optional `keep_attrs` is compatible with existing callsites.
