# FVK Findings

Status: constructed from public intent, source review, and proof obligations;
not machine-checked.

## F1: Reported merge conflict from consumed stacked metadata

Input: the issue MCVE, where both variables have only dimension `x` and are
stacked with `new_dim="y"` and `sample_dims=["x"]`.

Observed before repair: `to_unstacked_dataset("y")` selected each variable but
left scalar stacked coordinate metadata on the selected arrays. `Dataset(...)`
then tried to merge different scalar values for coordinate `y`, producing the
reported `MergeError`.

Expected: a dataset identical to the original `{"a": arr, "b": arr}`.

Status: repaired. V2 drops the consumed stacked dimension name and selected
level coordinate from each selected array before dataset construction. This is
covered by PO3 and PO7.

## F2: V1 over-squeezed legitimate length-one sample dimensions

Input: the same single-dimension roundtrip family as the issue, but with sample
dimension `x` of length one.

Observed in V1 by source inspection: `.squeeze(drop=True)` had no `dim`
argument, so it would remove every length-one dimension from each selected
array. That would remove `x` even though `sample_dims=["x"]` means `x` was not
stacked and should be preserved.

Expected: `x` remains a dimension in the reconstructed dataset, because
`to_unstacked_dataset` is specified as the inverse of `to_stacked_array` and
sample dimensions are frame conditions.

Status: repaired in V2. The code now computes `dims_to_squeeze` explicitly:
the consumed stacked dimension is squeezed only when singleton and not carrying
real remaining levels, and remaining stacked levels are squeezed only when
represented by a single null missing-level sentinel. This is covered by PO4 and
PO5.

## F3: Existing public behavior must remain compatible

Input: existing local uses of `to_unstacked_dataset("features")`, including
same-dimensional and mixed-dimensional variables, plus the non-MultiIndex error
case.

Observed risk: repairing F1 by using `compat="override"` or by dropping all
level coordinates would mask real conflicts or remove real dimensions.

Expected: mixed-dimensional roundtrips preserve real stacked levels, remove
missing-level placeholders, and keep the `ValueError` guard unchanged.

Status: V2 chooses targeted coordinate dropping and targeted squeezing instead.
This is covered by PO1, PO5, PO6, and PO8.

## F4: Targeted squeeze list should not introduce duplicate dimension names

Input: a stacked coordinate whose level names overlap with the stacked
dimension name.

Observed risk during V2 review: the consumed stacked dimension can be added to
`dims_to_squeeze` first, and a later level-name pass could try to add the same
name again for unusual hand-built MultiIndexes.

Expected: the repair should not introduce a duplicate-dimension squeeze request
while preserving the same public method contract.

Status: repaired defensively. V2 checks `name not in dims_to_squeeze` before
adding a missing-level dimension from the level-name pass. This supports PO8.

## Residual risk

The proof is constructed, not machine-checked. The abstract `.k` model covers
the issue family and the one-real-level mixed-dimensional behavior evidenced by
the local tests. It does not establish total correctness or every arbitrary
hand-built MultiIndex shape.
