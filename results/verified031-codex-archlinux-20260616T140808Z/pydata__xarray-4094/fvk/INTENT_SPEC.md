# Intent Spec

Status: constructed from public/local evidence only; not machine-checked.

## Required behavior

1. `DataArray.to_unstacked_dataset(dim, level=0)` requires `dim` to name a
   stacked coordinate backed by a `pandas.MultiIndex`. If it is not stacked, the
   method raises `ValueError` with the existing message shape.
2. The method expands one MultiIndex level into dataset variables. The selected
   level is consumed as output variable names, not retained as a shared
   coordinate that must merge across output variables.
3. For arrays produced by `Dataset.to_stacked_array`, the method is the inverse
   operation: each output variable must match the corresponding original
   variable's dimensions, coordinates, and values for the covered roundtrip
   cases.
4. A dataset whose variables have only sample dimensions is in scope. The public
   issue requires this roundtrip to work instead of raising `MergeError`.
5. Legitimate sample dimensions must be preserved even when their length is one;
   only the consumed stacked coordinate and placeholder dimensions introduced
   for missing stacked levels may be squeezed away.
6. Existing mixed-dimensional behavior remains in scope: variables that had a
   real stacked level keep it, while variables that used the missing-level
   sentinel lose that placeholder dimension.

## Boundary

This audit focuses on the method body changed by the fix and the public
roundtrip behavior evidenced by the issue, docstring, and existing local tests.
It does not claim machine-checked coverage of every possible arbitrary
MultiIndex shape a user could construct by hand.
