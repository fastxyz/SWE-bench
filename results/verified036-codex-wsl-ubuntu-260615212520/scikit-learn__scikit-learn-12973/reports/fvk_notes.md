# FVK Notes

## Decisions

The V1 behavioral fix stands. F-001 and F-002 describe the two mixed-routing bugs present before the patch, and PO-1 through PO-3 show that the current source resolves one local `copy_X` value and passes it to both `_preprocess_data` and `lars_path`.

I made one V2 source refinement: the `LassoLarsIC.fit` docstring now says `copy_X : boolean or None, optional, default None`. This is traced to F-003 and PO-5; once `None` is the public sentinel, the documented type should include it.

I did not remove `copy_X` from `fit`. That alternative is rejected by PO-4 because the issue explicitly calls out backward compatibility for existing callers.

I did not mutate `self.copy_X` inside `fit`. No finding or proof obligation requires permanent estimator hyperparameter mutation; F-001/F-002 and PO-1/PO-2 require per-call routing consistency only.

## Artifacts

The FVK artifacts are in `fvk/`. The constructed mini-K model is `fvk/mini-copy-routing.k`, and the constructed claims are `fvk/lasso-lars-ic-copy-x-spec.k`. The required markdown artifacts are `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`.

## Execution Caveat

No tests, Python code, `kompile`, `kast`, or `kprove` were run. This follows the task constraints and is recorded as F-004/PO-6.
