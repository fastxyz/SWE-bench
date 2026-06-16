# FVK Iteration Guidance

Status: V1 stands unchanged.

## Recommended Source Action

No additional source edit is justified by the FVK audit. The V1 change
implements the intent-derived split:

- ignored bystander coordinate dimensions are not checked for monotonicity;
- actual concat dimensions are still checked for global monotonicity.

## Rejected Follow-Up Changes

1. Remove the final monotonicity check entirely.

Rejected because `SPEC.md` I3/I4 and `PROOF_OBLIGATIONS.md` PO-4 require the
existing impossible-ordering error for dimensions that are actually selected
for concatenation.

2. Restore validation over every dimension in the concatenated result.

Rejected because `SPEC.md` I1/I2 and `PROOF_OBLIGATIONS.md` PO-1 through PO-3
require bystander coordinate dimensions to remain outside the validation scope.

3. Recompute bystander dimensions after `_combine_nd`.

Rejected because `_infer_concat_order_from_coords` already computes the
contract-relevant set, `concat_dims`. Recomputing would add surface area
without discharging any additional proof obligation.

## Suggested Tests For A Future Executable Environment

Do not add tests in this task; test files are fixed and hidden. In a normal
development environment, add or keep public tests for:

- the reported case: two datasets varying along `x` and sharing identical
  non-monotonic `y`, expecting successful combination;
- the impossible-ordering case along a real concat dimension, expecting the
  existing `ValueError`;
- a multidimensional case with one varying concat dimension and one identical
  non-monotonic bystander dimension.

## Verification Follow-Up

If K tooling becomes available, materialize the claim schema from
`PROOF_OBLIGATIONS.md` into `mini-xarray-combine.k` and
`combine-by-coords-spec.k`, then run the commands recorded in `SPEC.md` and
`PROOF.md`. Until that happens, keep all tests; no test removal is recommended.
