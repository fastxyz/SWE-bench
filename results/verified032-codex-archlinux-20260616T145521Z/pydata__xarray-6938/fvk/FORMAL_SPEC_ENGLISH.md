# Formal Spec English

Constructed, not machine-checked.

## Claims paraphrased from `swap-dims-spec.k`

C-001 `swapDimsPromoteIndexNoMutation`: For an input heap containing an existing `IndexVariable` object `V` with dimensions `OldDims`, running the V1 promoted-result branch `toIndex(V).copy(deep=False); setDims(NewDims)` produces a result variable object `R` whose dimensions are `NewDims`, while the original object `V` still has dimensions `OldDims`. `R` is not `V`.

C-002 `swapDimsPromoteBaseNoMutation`: For an input heap containing an ordinary `Variable` object `V` with dimensions `OldDims`, running the V1 promoted-result branch produces an index variable result object `R` whose dimensions are `NewDims`, while the original object `V` still has dimensions `OldDims`. `R` is not `V`.

C-003 `swapDimsBaseBranchNoMutation`: For a variable not named by a result dimension, `to_base_variable(); setDims(NewDims)` mutates only the newly constructed base variable in the result. The input variable remains unchanged.

C-004 `swapDimsOldPromoteBugWitness`: The pre-V1 promoted-result branch `toIndex(V); setDims(NewDims)` mutates the input when `V` is already an `IndexVariable`, because `toIndex(V)` returns `V`. This is a bug witness, not a desired behavior claim.

C-005 `swapDimsValidationFrame`: V1 does not alter the validation predicates before the loop: invalid source dimensions and invalid replacement variables continue to raise before any result variables are constructed.

## Frame conditions

FRC-001. The input dataset's variable objects preserve their `dims` metadata across an in-domain `swap_dims()` call.

FRC-002. The returned dataset may contain new variable objects whose `dims` are rewritten.

FRC-003. The proof is about variable-object metadata aliasing and dimension rewriting. It does not prove termination, full pandas index semantics, or full xarray indexing semantics.
