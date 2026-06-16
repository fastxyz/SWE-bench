# Formal Spec In English

This file paraphrases the K-style claims in `coarsen-construct-spec.k`.

## CLAIM: LOOP-PRESERVES-NAMES

During the `for key, var in obj.variables.items()` loop, after any prefix of
variables has been processed, every processed variable name is present in the
reshaped dataset's variable-name set. When the loop has processed all original
variables, every original coordinate name is therefore present as a variable in
`reshaped`.

## CLAIM: COORD-PRESERVATION-V2

For any in-domain `Coarsen.construct` call where the original coordinate-name
set is a subset of the original variable-name set, the V1/V2 implementation
returns an object whose coordinate-name set contains every original coordinate
name.

The claim does not require the result coordinate-name set to be exactly equal
to the original set; it only proves the preservation property required by the
issue.

## CLAIM: PREFIX-COUNTEREXAMPLE

The pre-fix implementation used `original_coords intersect window_dim_names` as
the names passed to `set_coords`. For an original coordinate named `day` and a
coarsened dimension named `time`, where `day` is not in the `window_dim` key
set, the pre-fix result does not mark `day` as a coordinate. This is the public
issue's counterexample mechanism.

## CLAIM: DATAARRAY-TEMP-PRESERVATION

For a DataArray input, the temporary dataset has variable names equal to the
DataArray coordinate names plus `_THIS_ARRAY`, and coordinate names equal to
the DataArray coordinate names. Passing `set(self.obj.coords)` to `set_coords`
therefore preserves the DataArray's real coordinates and does not rely on
marking `_THIS_ARRAY` as a coordinate.

