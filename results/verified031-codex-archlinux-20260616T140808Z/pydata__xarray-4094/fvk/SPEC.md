# FVK Spec

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Target

`repo/xarray/core/dataarray.py`: `DataArray.to_unstacked_dataset`.

## Public intent ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The controlling entries are:

- E1-E3: the issue requires a working roundtrip for variables with only sample
  dimensions and identifies `MergeError` from conflicting stacked coordinate
  values as the observed failure.
- E4-E5: the docstrings say `to_unstacked_dataset` is the inverse of
  `Dataset.to_stacked_array`, and `sample_dims` are dimensions that are not
  stacked.
- E6-E7: local tests require existing mixed-dimensional roundtrips and the
  non-stacked `ValueError` behavior to remain.

## Contract

Precondition for successful reconstruction: `dim` names a coordinate whose
index is a `pandas.MultiIndex`, and `level` identifies one level of that index.
If this precondition fails because `dim` is not stacked, the method raises the
existing `ValueError`.

For each label `k` in the selected level:

1. Select the data for `k`.
2. Squeeze only dimensions that are consumed stacked metadata:
   - `dim`, if it is still a singleton dimension after selection and does not
     represent a remaining real MultiIndex level;
   - remaining stacked levels that are represented by a single null sentinel,
     meaning `to_stacked_array` introduced them only because the original
     variable did not have that dimension.
3. Preserve all legitimate sample dimensions, including length-one dimensions.
4. Drop coordinate variables named `dim` and `variable_dim`, because those names
   are consumed by reconstruction and must not be merged across output
   variables.
5. Construct the output `Dataset` from the cleaned selected arrays.

## Formal core

The abstract semantics and claims are in:

- `fvk/mini-xarray-unstack.k`
- `fvk/to-unstacked-dataset-spec.k`

They model the reconstruction loop at the property level: variable-label
selection, targeted squeezing, coordinate dropping, and dataset construction.
The model intentionally abstracts away xarray's full indexing implementation
but preserves the observed property axes: dimensions, coordinate presence, null
missing-level sentinels, and merge compatibility.

## Exact commands to machine-check later

These commands are recorded only; the task forbids executing them here.

```sh
kompile fvk/mini-xarray-unstack.k --backend haskell
kast --backend haskell fvk/to-unstacked-dataset-spec.k
kprove fvk/to-unstacked-dataset-spec.k
```
