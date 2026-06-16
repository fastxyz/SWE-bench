# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Target

The proof target is `Dataset.swap_dims()` in `repo/xarray/core/dataset.py`, specifically the loop that constructs result variables and assigns rewritten dimensions.

V1 changed the promoted-result branch from:

```python
var = v.to_index_variable()
var.dims = dims
```

to:

```python
var = v.to_index_variable().copy(deep=False)
var.dims = dims
```

## Claims

The K-style claims are in `fvk/swap-dims-spec.k` and paraphrased in `fvk/FORMAL_SPEC_ENGLISH.md`.

- C-001 proves no mutation for the reported `IndexVariable` promotion case.
- C-002 proves no mutation for ordinary variables promoted to index variables.
- C-003 proves no mutation for the non-promoted base-variable branch.
- C-004 records the old bug witness.
- C-005 records that validation behavior is unchanged.

## Proof sketch

1. Validation is unchanged. The V1 edit is after both existing `ValueError` checks, so out-of-domain behavior for missing source dimensions and invalid replacement variables is preserved. This discharges PO-005.

2. For each variable, `dims` is a new tuple computed from the input variable's old dimensions and `dims_dict`. This tuple construction does not mutate the variable.

3. Promoted branch, ordinary `Variable` case: `Variable.to_index_variable()` constructs a new `IndexVariable`. V1 then calls `copy(deep=False)`, which constructs another distinct `IndexVariable` with equivalent shallow data/metadata. The subsequent `var.dims = dims` updates only that copied object. The original input variable object remains unchanged. This discharges PO-001, PO-002, and PO-003 for ordinary variables.

4. Promoted branch, existing `IndexVariable` case: `IndexVariable.to_index_variable()` returns `self`, which is the pre-V1 aliasing hazard. V1 immediately calls `copy(deep=False)`, yielding a distinct `IndexVariable` object. The subsequent `var.dims = dims` updates the copy, not the original input variable. This is the issue's concrete failing path and discharges PO-001, PO-002, and PO-003 for the reported case.

5. Non-promoted branch: `to_base_variable()` constructs a fresh `Variable` object before `.dims` is assigned. Therefore the assignment cannot mutate the input variable object. This discharges PO-004 and the remaining PO-001 cases.

6. `_replace_with_new_dims(...)` constructs the returned dataset from the new `variables` mapping. The input dataset's `_variables` mapping and the variable objects it contains are not mutated by the V1 branch assignments. This composes the per-variable proof into the dataset-level frame condition.

## Bug witness for pre-V1

In the old promoted branch, if `v` is an `IndexVariable`, then `v.to_index_variable()` returns `v`. The assignment `var.dims = dims` is therefore exactly `v.dims = dims`, mutating the input dataset's variable object. This matches the issue's reported symptom that `ds2["lev"]` changes from dimension `z` to dimension `lev` after calling `ds2.swap_dims(z="lev")`.

## Residual risk

- Constructed, not machine-checked: the K commands were not run.
- Partial correctness only: termination is not separately proved. The edited loop is finite over `self.variables.items()`, but the FVK artifact does not machine-prove that fact.
- The mini semantics model object identity and metadata mutation, not full pandas/xarray behavior.

## Reproduce the machine check later

Do not run these in this benchmark workspace. They are the commands to use in an environment with K installed:

```sh
kompile fvk/mini-python-swapdims.k --backend haskell
kast --backend haskell fvk/swap-dims-spec.k
kprove fvk/swap-dims-spec.k
```

Expected machine-check result: `kprove` returns `#Top` for the V1 no-mutation claims. The old-branch bug witness is expected to show the pre-V1 mutation, not to be used as a desired-behavior proof.

## Test guidance

No tests were modified. Existing `swap_dims` tests should be kept until the K proof is machine-checked. A regression test for the issue shape would assert that the returned dataset promotes `lev` while the original `ds2["lev"].dims` remains `("z",)`, but adding tests is outside this task.
