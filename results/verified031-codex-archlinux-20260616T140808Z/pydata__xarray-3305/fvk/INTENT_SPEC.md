# Intent Spec

Status: constructed from public evidence only; no hidden tests, evaluator output,
internet, or upstream fix knowledge used.

## Intended behavior

1. `DataArray.quantile(q, dim=..., keep_attrs=True)` must preserve the original
   `DataArray.attrs` in the returned `DataArray`.
2. `DataArray.attrs` are the attrs of the underlying `Variable`, so preserving
   attrs through `DataArray.quantile` requires preserving variable-level attrs
   across the temporary dataset path.
3. `Variable.quantile` should accept a `keep_attrs` argument and, when it is
   true, copy the original variable attrs to the quantile result.
4. `Dataset.quantile` should pass the resolved `keep_attrs` setting into each
   reduced variable, while retaining the existing dataset-level attrs behavior.
5. `keep_attrs=False` must continue to drop attrs. `keep_attrs=None` must follow
   the existing xarray global option resolution with default `False`.
6. Numeric quantile values, dimension removal/addition, dask rejection, invalid
   dimension handling, and interpolation behavior are intended to remain as in
   the existing quantile implementation. This FVK pass models those value/shape
   effects as a frame around the attrs obligation.
7. Public compatibility must be preserved: existing callers of
   `Variable.quantile(q, dim=..., interpolation=...)` must remain valid, and
   dispatch from `DataArray`, `Dataset`, and `GroupBy` quantile must still work.

## Domain

The attrs-preservation claims cover non-dask `Variable`, `Dataset`, and
`DataArray` quantile calls that are already in the public quantile domain:
valid `q`, valid `dim`, supported interpolation, and data accepted by the
existing `np.nanpercentile` call. Existing out-of-domain behavior is framed:
dask arrays still raise before result construction, and invalid dims still raise
through the existing dimension validation path.

## Non-goals

This pass does not prove the numerical correctness of `numpy.nanpercentile`.
The formal model treats the numeric result as an uninterpreted value
`quantileData(DATA, Q, DIM, INTERP)` and proves that the attrs attached to that
result are correct. This is adequate for the reported defect because the
passing and failing cases differ only in the attrs map.
