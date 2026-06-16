# Public Compatibility Audit

Status: no unresolved compatibility findings.

## Changed public or semi-public symbols

### `xarray.core.variable.Variable.quantile`

- V1/V2 signature: `quantile(self, q, dim=None, interpolation="linear", keep_attrs=None)`.
- Compatibility: adding a trailing optional parameter preserves existing calls
  of the form `v.quantile(q)`, `v.quantile(q, dim=...)`, and
  `v.quantile(q, dim=..., interpolation=...)`.
- Public callsites found under `repo/xarray`: visible direct calls in
  `xarray/tests/test_variable.py`; internal call from `Dataset.quantile`.
- Overrides: `IndexVariable` inherits `Variable.quantile`; no overriding
  `IndexVariable.quantile` definition was found. `DataArray`, `Dataset`, and
  `GroupBy` define their own public `quantile` methods, already accepting
  `keep_attrs`.
- V2 status: compatible.

### `xarray.core.dataset.Dataset.quantile`

- Signature unchanged.
- Behavior change when resolved `keep_attrs=True`: variable attrs are now
  preserved in addition to existing dataset attrs.
- Public callsites found under `repo/xarray`: `DataArray.quantile` delegates to
  this method; groupby applies class quantile methods; visible dataset tests use
  existing calls without `keep_attrs`.
- V2 status: compatible with existing call shape; behavior aligns with
  keep_attrs intent and `Dataset.reduce` pattern.

### `xarray.core.dataarray.DataArray.quantile`

- Signature unchanged.
- V2 code docstring now says "array's attributes" rather than "dataset's
  attributes" for `keep_attrs`.
- V2 status: compatible; documentation now matches public intent and actual
  attr storage.
