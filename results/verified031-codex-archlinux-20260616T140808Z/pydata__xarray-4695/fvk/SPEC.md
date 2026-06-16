# FVK Spec

Status: constructed, not machine-checked.

## Target

The audited behavior is label-selection dispatch from dimension-indexer
mappings into `.sel`.

Primary source target:

- `repo/xarray/core/dataarray.py`, private `_LocIndexer.__getitem__`, the public
  implementation behind `DataArray.loc[...]`.

Related source targets found by the audit:

- `repo/xarray/core/computation.py`, `_iter_over_selections`, which dynamically
  constructs a single dimension indexer before calling `.sel`.
- `repo/xarray/core/groupby.py`, `GroupBy._yield_binary_applied`, which
  dynamically constructs a single group-dimension indexer before calling
  `.sel`.

No loops or recursive functions are in this target slice.

## Public Intent Ledger

The standalone ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1 and E2: `.loc` must not fail when a dimension is named `method`.
- E3: dimension names are irrelevant, so reserved `.sel` parameter names must
  remain legal dimension names in dynamic indexer dispatch.
- E4: the observed failure is caused by `self.data_array.sel(**key)`.
- E5 and E6: `.loc` dictionary input is by-name label indexing.
- E7: `.sel` separates positional `indexers` from reserved options.
- E8: `Dataset.loc` already uses `dataset.sel(key)`.

## Contract

For any in-domain indexer mapping `M`:

1. `DataArray.loc[M]` dispatches to `.sel(M)`, not `.sel(**M)`.
2. If `.loc` receives a tuple, scalar, slice, ellipsis-containing key, or other
   non-mapping key accepted by existing code, the key is expanded to
   `dict(zip(data_array.dims, labels))`; the resulting mapping is then
   dispatched as `.sel(M)`.
3. If `M` contains keys such as `method`, `tolerance`, or `drop`, those keys
   remain entries in `M`. They do not bind the reserved `.sel` parameters.
4. Internal helpers that build `{dim: value}` from a dynamic dimension name
   dispatch that dictionary as `.sel({dim: value})`.
5. Downstream `.sel`, `Dataset.sel`, `remap_label_indexers`, and pandas index
   behavior are framed: the fix changes how indexers are passed into `.sel`, not
   how valid labels are resolved after `.sel` receives them.

## Preconditions

- The mapping keys are valid xarray dimension, coordinate, or multi-index level
  indexer names for the receiving object.
- Label values, slices, arrays, and DataArray indexers are in the existing
  domain accepted by `.sel`.
- Direct `.sel` calls using reserved keyword names remain governed by the
  documented `.sel` signature; users who need a colliding dimension name with
  direct `.sel` must use `.sel({"method": value})`.

## Frame Conditions

- No public method signatures change.
- `Dataset.loc` behavior is unchanged; it already uses positional mapping
  dispatch.
- `DataArray.sel` and `Dataset.sel` retain reserved parameters `method`,
  `tolerance`, and `drop`.
- Error behavior for invalid labels or dimensions remains downstream.

## Formal Core

The K artifacts are:

- `mini-python-loc.k`: a minimal dispatch semantics that distinguishes
  positional indexer mappings from keyword argument binding.
- `dataarray-loc-spec.k`: reachability claims for `.loc` and dynamic helper
  dispatch, plus a diagnostic legacy counterexample.

The model intentionally abstracts away full xarray objects and pandas indexes.
It keeps the verified property visible: whether a key named `method` is carried
inside the indexer mapping or becomes the reserved `.sel(method=...)` argument.
