# Formal Spec English

Status: paraphrase of the abstract K claims in
`fvk/to-unstacked-dataset-spec.k`; constructed, not machine-checked.

## Claim C1: Non-stacked guard

If `to_unstacked_dataset` is called with a dimension whose index is not a
MultiIndex, the method reaches the existing `ValueError` outcome and does not
attempt reconstruction.

## Claim C2: Single-level stacked roundtrip

For every stacked array produced from variables that have only sample
dimensions, selecting each variable label consumes the stacked dimension and the
variable level coordinate. The output dataset contains one variable per label,
and no output variable retains `dim` or `variable_dim` as a coordinate to be
merged. Sample dimensions are unchanged, including dimensions of length one.

## Claim C3: Mixed one-real-level roundtrip

For every covered stacked array with one remaining real stacked level, selecting
a variable preserves that level when its selected coordinate is not null. If the
selected variable only has the missing-level sentinel for that level, the
sentinel dimension is squeezed and dropped. The consumed stacked dimension and
selected level coordinate are not retained as output coordinates.

## Claim C4: Merge compatibility

The dataset constructor receives data variables whose coordinates no longer
contain the consumed stacked coordinate metadata. Therefore, variables selected
from different labels cannot conflict solely because their consumed stacked
coordinate scalar values differ.

## Claim C5: Public compatibility

The public method signature, exception type for non-stacked coordinates, and
return type remain unchanged.
