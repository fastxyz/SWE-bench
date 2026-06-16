# FVK Specification

Status: constructed, not machine-checked. The formal core is in
`fvk/mini-xarray.k` and `fvk/quantile-attrs-spec.k`.

## Public intent ledger

The public evidence ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical
entries mirrored into the formal claims:

- E1/E2: `DataArray.quantile(..., keep_attrs=True)` preserves original attrs.
- E3: the pre-fix `OrderedDict()` result is the reported bug, not intended
  behavior.
- E4/E6: `DataArray` attrs are the underlying variable attrs and flow through a
  temporary dataset during quantile.
- E5: `Variable.quantile` should have and honor `keep_attrs`.
- E7/E8: `keep_attrs=None` resolves through `_get_keep_attrs(default=False)` and
  the resolved value is passed to each variable quantile.
- E9: adding `keep_attrs` must not break existing quantile callsites.
- E10: the `DataArray.quantile` keep_attrs docstring should name array attrs.

## Spec domain

The verified domain is the existing in-domain quantile path:

- data is not dask-backed, because existing `Variable.quantile` raises for dask;
- `q`, `dim`, and `interpolation` are accepted by the existing implementation;
- `np.nanpercentile` returns normally.

The proof is partial correctness over attrs: if the quantile call returns a
result, the attrs attached to that result obey `keep_attrs`. Numeric percentile
values and output dimensions are framed as `quantileData(DATA, Q, DIM, INTERP)`
and `quantileDims(DIMS, Q, DIM)`, because the patch did not change those
algorithms and the issue is specifically about attrs.

## Functional contracts

### `Variable.quantile`

For any variable `var(DIMS, DATA, ATTRS)` in domain:

- `keep_attrs=True` returns a variable with attrs `ATTRS`.
- `keep_attrs=False` returns a variable with empty attrs.
- `keep_attrs=None` is resolved by the global keep_attrs option with default
  `False`, then follows the corresponding true/false branch.
- Data and dimensions are those produced by the existing quantile computation.

### `Dataset.quantile`

For any dataset containing a reduced data variable:

- `keep_attrs` is resolved before variable reduction.
- The resolved value is passed to `Variable.quantile`.
- Dataset-level attrs continue to follow the existing behavior:
  preserve dataset attrs when resolved `keep_attrs` is true; otherwise use empty
  attrs.
- Coordinate variables and index filtering are framed as existing behavior.

### `DataArray.quantile`

For any data array `dataarray(var(DIMS, DATA, ATTRS), COORDS)`:

- converting to a temporary dataset places the data array's variable in that
  dataset without making the variable attrs into dataset attrs;
- dataset quantile must therefore preserve variable attrs for
  `DataArray.quantile(..., keep_attrs=True)` to return attrs `ATTRS`;
- when resolved `keep_attrs` is false, the result attrs are empty.

## Compatibility contract

Adding `keep_attrs=None` as a trailing optional argument to `Variable.quantile`
preserves existing public calls with three positional or keyword arguments. The
new internal call from `Dataset.quantile` targets xarray `Variable` objects and
`IndexVariable`, which inherits without overriding `quantile`.
