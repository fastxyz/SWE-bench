# FVK Findings

Status: constructed, not machine-checked.

## F1 - Legacy One-Shot CV Exhaustion

- Classification: code bug in pre-V1 behavior; fixed by V1.
- Evidence: E1/E2/E3.
- Input: `SequentialFeatureSelector(..., cv=cv.split(X, y, groups))` where the
  split iterable yields `S > 0` splits and the SFS search evaluates at least two
  candidate subsets.
- Observed pre-V1 behavior: first candidate consumes the generator; a later
  candidate sees zero splits and can reach the reported empty-score
  `IndexError`.
- Expected behavior: all candidates in the same fit are scored over reusable
  checked splits.
- FVK localization: `rawFit(oneShot(S), C)` with `C >= 2` reaches
  `failedEmptyScores`; `fit(oneShot(S), C)` does not.
- Resolution: V1 calls `check_cv` once in `fit` and passes the checked object to
  every candidate-scoring call.
- Related proof obligations: PO-1, PO-2, PO-3, PO-4.

## F2 - V1 Source Audit Confirms the Intended Normalization Point

- Classification: confirmation; no source change required.
- Evidence: E4/E8/E10.
- Input: any valid `cv` supplied to one `SequentialFeatureSelector.fit`.
- Observed V1 behavior by source inspection: `fit` computes
  `cv = check_cv(self.cv, y, classifier=is_classifier(cloned_estimator))` once
  before the candidate loop, and `_get_best_new_feature_score` passes that local
  `cv` to `cross_val_score`.
- Expected behavior: normalize once per fit, not once per candidate and not
  never.
- Resolution: V1 already matches the intended mechanism.
- Related proof obligations: PO-2, PO-4, PO-5.

## F3 - Empty Split Iterables Remain Outside the Proven Domain

- Classification: missing precondition / malformed input boundary.
- Evidence: `cross_validate` aggregates scores from `cv.split(...)`; an empty
  iterable gives no scores independent of generator exhaustion.
- Input: `cv=[]` or a generator yielding zero splits.
- Observed/expected: V1 does not add a new guard or custom error for empty CV
  iterables. This is outside the reported issue because no valid scoring split
  exists.
- Recommended next step: if the project wants clearer diagnostics for empty CV
  iterables, address it in shared model-selection validation rather than in SFS.
- Related proof obligations: PO-7.

## F4 - Reusing the Same Generator Across Separate Fit Calls Is Not Guaranteed

- Classification: underspecified intent / residual boundary.
- Evidence: E5/E8 and the nature of one-shot iterables.
- Input: construct one generator object, fit once, then call `fit` again on the
  same SFS instance with the same already-consumed generator stored in `self.cv`.
- Observed/expected: V1 fixes repeated consumption within one fit. It does not
  make a consumed generator reusable across separate fits, matching the local
  `check_cv` behavior used by other estimators.
- Recommended next step: document or test this only if public intent expands to
  require repeated fitting with the same one-shot generator object.
- Related proof obligations: PO-7.

## Proof-Derived Findings From `/verify`

- The proof construction required the side condition `S > 0`, recorded in F3.
- The proof construction required candidate count `C >= 0`, which is structural:
  a loop cannot execute a negative number of candidate evaluations.
- No proof obstacle required a source change beyond V1.
