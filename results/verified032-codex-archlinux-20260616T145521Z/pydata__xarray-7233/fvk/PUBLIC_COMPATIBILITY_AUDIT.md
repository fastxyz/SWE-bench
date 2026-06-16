# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbol

- `Coarsen.construct` in `repo/xarray/core/rolling.py`

## Compatibility review

| Surface | Status | Evidence |
|---|---|---|
| Signature | Compatible | V1 changes only the local value assigned to `should_be_coords`; parameters and return type are unchanged. |
| Dataset caller behavior | Compatible | The method still returns a `Dataset` for `DatasetCoarsen`; the coordinate set is expanded to include all original coordinates, as required by public issue intent. |
| DataArray caller behavior | Compatible | The method still returns through `_from_temp_dataset`; `set(self.obj.coords)` excludes `_THIS_ARRAY`, so no new public parameter or dispatch requirement is introduced. |
| Subclass / override dispatch | Compatible | No method call signature was changed and no new virtual keyword argument was added. |
| Producer / consumer shape | Compatible | Variable names and reshaped dimensions are produced by the existing loop. V1 only changes coordinate membership classification after those variables are present. |
| Tests | Not modified | Benchmark instructions forbid modifying test files; no tests were changed. |

No unhandled public callsite, override, or signature compatibility issue was
found.

