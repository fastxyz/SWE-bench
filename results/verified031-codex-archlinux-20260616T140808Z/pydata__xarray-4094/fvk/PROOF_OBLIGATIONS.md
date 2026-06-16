# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Non-stacked guard

For any `DataArray` where `self.indexes[dim]` is not a `pandas.MultiIndex`,
`to_unstacked_dataset(dim, level)` raises `ValueError` before reconstruction.

Evidence: E7. Code: `repo/xarray/core/dataarray.py:1953`.

## PO2: Variable-label coverage

For each label `k` in the selected MultiIndex level, the reconstruction loop
creates exactly one entry `data_dict[k]`.

Evidence: E3-E4. Code: `repo/xarray/core/dataarray.py:1957-1964`.

## PO3: Consumed coordinate metadata is removed

For each selected variable, coordinate variables named `dim` and
`variable_dim` are removed before `Dataset(data_dict)` merges coordinates.

Evidence: E2-E4. Code: `repo/xarray/core/dataarray.py:1995-1997`.

## PO4: Sample dimensions are preserved

No legitimate sample dimension is squeezed solely because its length is one.
Only names in `dims_to_squeeze` are passed to `squeeze`; the consumed stacked
dimension is added only when it remains singleton after selection and does not
represent a remaining real MultiIndex level.

Evidence: E4-E5 and F2. Code: `repo/xarray/core/dataarray.py:1966-1993`.

## PO5: Missing stacked-level placeholders are removed

If a remaining stacked level is present as a dimension with a single null
coordinate value, it is a missing-level sentinel introduced by
`to_stacked_array` and is squeezed with `drop=True`.

Evidence: E4 and E6. Code: `repo/xarray/core/dataarray.py:1982-1993`.

## PO6: Real remaining stacked levels are preserved

If a remaining stacked level has a non-null coordinate value, it is not added
to `dims_to_squeeze` by the V2 logic, even if its length is one.

Evidence: E4-E6. Code: `repo/xarray/core/dataarray.py:1967-1993`.

## PO7: Merge conflict absence for the issue family

For the issue family with no non-sample stacked dimensions, after selection and
targeted squeezing, each output variable lacks the conflicting scalar stacked
coordinate. Therefore `Dataset(data_dict)` has no coordinate named `dim` whose
values differ between `a` and `b`.

Evidence: E1-E3 and F1. Code: `repo/xarray/core/dataarray.py:1964-1996`.

## PO8: Public compatibility

The method signature, return type, non-MultiIndex error behavior, and existing
mixed-dimensional public behavior remain compatible.

Evidence: E6-E7 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO9: Honesty gate

The proof artifacts and commands are emitted, but no K or Python tooling is
executed. Test removal is not recommended without machine-checking.

Evidence: task instructions and FVK verify guidance.
