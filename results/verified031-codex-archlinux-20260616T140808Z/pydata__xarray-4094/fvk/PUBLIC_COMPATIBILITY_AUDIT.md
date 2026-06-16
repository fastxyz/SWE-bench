# Public Compatibility Audit

Status: constructed from local source search; not machine-checked.

## Changed public symbol

- `xarray.core.dataarray.DataArray.to_unstacked_dataset(self, dim, level=0)`

## Compatibility results

- Signature: unchanged.
- Return type: still constructs and returns `Dataset(data_dict)`.
- Non-MultiIndex error behavior: unchanged.
- Public callsites found in local tests/docs: existing calls use
  `to_unstacked_dataset("features")` or `to_unstacked_dataset(dim="z")` and do
  not depend on the internal squeeze strategy.
- Virtual dispatch/overrides: no subclass override was found in the allowed
  source tree.

## Conclusion

No public compatibility issue is introduced by V2. The behavioral change is
limited to preserving legitimate length-one dimensions and dropping only
consumed stacked metadata or missing-level placeholders.
