# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found no source-code issue that requires a V2
patch. The remaining open items are proof/tooling boundaries, not implementation
defects.

## Trace To Findings And Obligations

- Kept the V1 `x`-first `apply_ufunc` call because Finding F1 identifies the old
  callable as the coordinate-attrs bug, and proof obligation O4 requires
  coordinate attrs to be selected from coordinate variables rather than from
  `x.attrs`.
- Kept the post-call `result.attrs = x_attrs` normalization because Finding F2
  and proof obligation O5 require scalar `x` to contribute empty attrs instead
  of accidentally selecting attrs from `cond` or `y`.
- Kept the Dataset data-variable attrs normalization because Finding F3 and
  proof obligation O3 require `ds_x[var].attrs`, not `ds_x.attrs`, on each
  result data variable.
- Accepted the internal argument reorder as intentional because Finding F4 ties
  it to public evidence: the `where` docstring says attrs come from `x`, and
  `DataArray.where` / `Dataset.where` already place the data object first.
  This discharges O1, O2, O4, and O7.
- Made no edits for Findings F5 and F6 because they are proof-scope/tooling
  limitations. They require future machine-checking and integration tests, not a
  source change.

## Execution Constraints

No tests, Python, or K tooling were run. The proof is constructed and recorded in
`fvk/PROOF.md`, but not machine-checked.
