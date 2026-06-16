# FVK Spec: `combine_by_coords` Identical Coordinate Handling

Status: constructed from public intent and source inspection; not
machine-checked.

## Scope

This spec audits the V1 change in `repo/xarray/core/combine.py` for
`combine_by_coords`, specifically the final global-index monotonicity check
after `_infer_concat_order_from_coords` and `_combine_nd`.

The proof target is partial correctness for the validation policy: if
`combine_by_coords` reaches the post-combination validation step, it must check
only dimensions selected for concatenation, and it must not reject identical
non-varying coordinate dimensions solely because they are non-monotonic.

## Public Intent Ledger

I1. Source: `benchmark/PROBLEM.md`

Quoted evidence: "`combine_by_coords` should return without error" for two
datasets whose `x` coordinates vary and whose identical `y` coordinate is
`['a', 'c', 'b']`.

Semantic obligation: A coordinate dimension whose coordinate values are
identical across the datasets is a bystander; non-monotonicity of that
bystander coordinate is not a valid reason for the reported `ValueError`.

Status: encoded in the spec as the bystander-dimension postcondition.

I2. Source: `benchmark/PROBLEM.md` quoting the public docs.

Quoted evidence: "Non-coordinate dimensions will be ignored, as will any
coordinate dimensions which do not vary between each dataset."

Semantic obligation: Coordinate dimensions that do not vary between datasets
must be ignored by the automatic coordinate-combination logic. They may be
present in the result, but they are not dimensions whose monotonicity controls
dataset ordering.

Status: encoded in the spec as the definition of `concat_dims` and the
validation frame condition.

I3. Source: `repo/xarray/core/combine.py` docstring for
`combine_by_coords`.

Quoted evidence: "Will attempt to order the datasets such that the values in
their dimension coordinates are monotonic along all dimensions. If it cannot
determine the order in which to concatenate the datasets, it will raise a
ValueError."

Semantic obligation: Dimensions selected for concatenation still require a
monotonic global index after combination; impossible inferred orderings must
continue to raise.

Status: encoded in the spec as the concat-dimension validation obligation.

I4. Source: public in-repo test evidence in
`repo/xarray/tests/test_combine.py`.

Quoted evidence: `test_check_for_impossible_ordering` expects
`ValueError: Resulting object does not have monotonic global indexes along
dimension x` for datasets with `x` chunks `[0, 1, 5]` and `[2, 3]`.

Semantic obligation: The fix must not remove the post-combination validation
for dimensions that actually vary and are selected for concatenation.

Status: supporting evidence for I3; not treated as an oracle beyond the public
intent it matches.

I5. Source: implementation evidence in `_infer_concat_order_from_coords`.

Quoted evidence: "If dimension coordinate values are same on every dataset
then should be leaving this dimension alone (it's just a 'bystander')."

Semantic obligation: The implementation already has a precise bystander
classification: dimensions whose indexes compare equal across all datasets are
not appended to `concat_dims`.

Status: used as implementation evidence for the proof mechanism, not as the
source of public intent.

## Definitions

- `indexes_equal(d)`: every dataset in the current data-variable group has an
  index for dimension `d`, and each such index equals the first dataset's index
  for `d`.
- `concat_dims`: the ordered list returned by
  `_infer_concat_order_from_coords`; a coordinate dimension is appended only
  when its indexes are not all equal across the group.
- `bystander_dim(d)`: `d` is a coordinate dimension in the combined result and
  `d not in concat_dims` because `indexes_equal(d)` held during inference.
- `global_monotonic(d)`: the combined result index for `d` is monotonic
  increasing or monotonic decreasing.

## Contract

C1. Bystander frame condition:

For any bystander coordinate dimension `d`, post-combination validation in
`combine_by_coords` must not inspect `global_monotonic(d)` and must not raise
`ValueError` solely because `global_monotonic(d)` is false.

C2. Concat-dimension validation:

For any `d in concat_dims`, if `d` exists as a coordinate dimension in the
combined result and `global_monotonic(d)` is false, `combine_by_coords` must
raise `ValueError("Resulting object does not have monotonic global indexes
along dimension d")`.

C3. Successful reported case:

For the reported input shape, where `x` varies monotonically across the two
datasets and `y` is identical but non-monotonic in each dataset, the
post-combination validation must not raise for `y`.

C4. Public compatibility:

The fix must not change the public signature, return type contract, grouping
strategy, data-variable merge behavior, or test files.

## Adequacy Check

The formalized contract is neither weaker nor stronger than the public intent:
it allows non-monotonicity only for ignored bystander coordinate dimensions,
while preserving the documented failure mode for dimensions actually used to
order concatenation.

The alternative interpretation that "monotonic along all dimensions" includes
ignored bystander coordinate dimensions is rejected because the following
sentence in the same public contract explicitly says coordinate dimensions
that do not vary are ignored.

## Non-Executed Formal Commands

The task forbids running K tooling. A full FVK run would materialize the claim
schema from `fvk/PROOF_OBLIGATIONS.md` into a mini xarray-combine K fragment and
then run:

```sh
kompile fvk/mini-xarray-combine.k --backend haskell
kast --backend haskell fvk/combine-by-coords-spec.k
kprove fvk/combine-by-coords-spec.k
```

Expected result after materialization: `kprove` returns `#Top` for the
bystander-frame and concat-dimension-validation claims.
