# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `Dataset.swap_dims()` in `repo/xarray/core/dataset.py`. The formal target is the variable-promotion branch that can convert a data variable into a dimension coordinate variable and then assign rewritten dimensions.

The audit intentionally models only the fragment needed for the reported bug: variable object identity, variable kind (`Variable` vs `IndexVariable`), `to_index_variable()`, `copy(deep=False)`, `to_base_variable()`, and `.dims` assignment. It does not model full xarray indexing, pandas index equality, or array computations.

## Intent summary

From `benchmark/PROBLEM.md` and public xarray docstrings:

- `swap_dims()` returns a new object with swapped dimensions.
- The original object must not be modified.
- In the reported shape, a data variable named by the replacement dimension becomes a dimension coordinate in the result.
- Existing validation and public API shape are preserved.

The complete intent-only list is in `fvk/INTENT_SPEC.md`. The evidence ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Contract

For an in-domain `Dataset.swap_dims(dims_dict)` call:

1. For each input variable `v`, the returned dataset contains a variable whose dimensions are `tuple(dims_dict.get(dim, dim) for dim in v.dims)`.
2. If the variable name is in the result-dimension set, that returned variable is an `IndexVariable`.
3. If the variable name is not in the result-dimension set, that returned variable is a base `Variable`.
4. No variable object stored in the input dataset has its `.dims` changed by the call.
5. Existing validation errors are unchanged.

The central frame condition is item 4. It is the property violated before V1.

## Public intent ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E-001/E-002: the issue states that input mutation is the bug and should not happen.
- E-003: the MVCE identifies the concrete aliasing case: `ds2["lev"]` changes dimensions after `ds2.swap_dims(z="lev")`.
- E-004: the docstring says `swap_dims()` returns a new object.
- E-007: implementation evidence localizes the root cause because `IndexVariable.to_index_variable()` returns `self`.
- E-009: implementation evidence supports the V1 repair because `IndexVariable.copy(deep=False)` returns a distinct variable object.

## Formal artifacts

- `fvk/mini-python-swapdims.k`: minimal object-aliasing semantics for the relevant xarray/Python fragment.
- `fvk/swap-dims-spec.k`: K-style reachability claims for the promoted index branch, promoted base branch, non-promoted base branch, validation frame, and old bug witness.
- `fvk/FORMAL_SPEC_ENGLISH.md`: English paraphrase of every nontrivial claim.
- `fvk/SPEC_AUDIT.md`: adequacy check comparing those paraphrases against public intent.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: compatibility check for the changed public method.

## Machine-check commands

These commands are intentionally not executed in this workspace:

```sh
kompile fvk/mini-python-swapdims.k --backend haskell
kast --backend haskell fvk/swap-dims-spec.k
kprove fvk/swap-dims-spec.k
```

Expected outcome if the mini semantics and claims are accepted by the K toolchain: `kprove` discharges the no-mutation claims for V1 and exposes the pre-V1 old-branch witness as the localized bug behavior.

## Verdict

The V1 source fix satisfies the stated contract. No additional production-code change is required by the FVK findings or proof obligations.
