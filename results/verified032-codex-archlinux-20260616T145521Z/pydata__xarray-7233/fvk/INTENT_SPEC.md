# Intent Spec

Status: constructed from public evidence only.

## In-domain operation

The audited unit is `Coarsen.construct` in `repo/xarray/core/rolling.py`.
The in-domain inputs are successful `Dataset.coarsen(...).construct(...)` and
`DataArray.coarsen(...).construct(...)` calls that already satisfy the existing
validation:

- `window_dim` is provided.
- Every coarsened dimension has exactly two replacement dimension names.
- `window_dim` names exactly the dimensions in `self.windows`.
- Existing `Variable.coarsen_reshape` preconditions for the chosen boundary and
  side are satisfied.

Invalid argument behavior is outside this issue's repair obligation and should
remain governed by the existing validation branches.

## Required behavior

I1. Variable-name preservation: `construct` may reshape dimensions and data, but
it must keep each original variable name present in the intermediate reshaped
dataset unless an existing validation error aborts the call.

I2. Coordinate-status preservation: for every variable name that is a coordinate
before `coarsen.construct`, the result must expose that same name as a
coordinate after `coarsen.construct`.

I3. Non-dimension coordinates are included in I2. The issue's `day` coordinate
is not a dimension coordinate, but it must remain a coordinate after `time` is
split into `("year", "month")`.

I4. Dimension coordinates are included in I2. Existing behavior that preserves
coordinates whose names are coarsened dimensions, such as `time`, must remain
valid.

I5. The public intent requires preservation of original coordinate membership,
not an exact guarantee that no additional coordinate can be introduced by
pre-existing xarray dimension-coordinate rules.

I6. The public API shape is unchanged: `Coarsen.construct` keeps its signature
and return kind (`Dataset` for dataset inputs, `DataArray` for data array
inputs).

