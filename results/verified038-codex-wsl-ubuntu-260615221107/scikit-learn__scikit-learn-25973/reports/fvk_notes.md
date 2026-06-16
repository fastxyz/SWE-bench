# FVK Notes

## Decision

V1 stands unchanged. The FVK audit confirmed that the source fix already
addresses the issue's root cause and did not surface a production-code change
that is justified by the public intent.

## Trace to Findings and Proof Obligations

### Keep `check_cv` normalization in `fit`

- Finding: F1 identifies the legacy bug as repeated consumption of a one-shot CV
  iterable during candidate scoring.
- Finding: F2 confirms V1 normalizes once per `fit`.
- Proof obligations: PO-2 requires single normalization before the candidate
  loop; PO-3 requires one-shot iterable materialization through `check_cv`.
- Source decision: keep the V1 line
  `cv = check_cv(self.cv, y, classifier=is_classifier(cloned_estimator))`.

### Keep passing the local checked CV into candidate scoring

- Finding: F1 says later candidates must score over reusable checked splits.
- Finding: F2 confirms `_get_best_new_feature_score` receives and uses the local
  checked `cv`.
- Proof obligations: PO-4 requires every candidate score to use the same checked
  CV object; PO-5 requires preserving existing behavior for integer, `None`, and
  splitter CV inputs.
- Source decision: keep the V1 helper signature
  `_get_best_new_feature_score(..., cv, current_mask)` and the
  `cross_val_score(..., cv=cv, ...)` call.

### Do not reject generators or add warnings

- Finding: F2 records that V1 matches the intended mechanism.
- Proof obligations: PO-1 preserves the public CV input domain; PO-6 preserves
  public API and parameter validation.
- Source decision: leave `_parameter_constraints["cv"]` unchanged and do not add
  a warning or generator-specific validation.

### Do not assign the checked object back to `self.cv`

- Finding: F2 confirms the local normalization point is sufficient.
- Proof obligations: PO-6 requires preserving public estimator parameter
  inspection and cloning behavior.
- Source decision: keep normalization local to `fit`; `self.cv` remains the
  user-provided constructor parameter.

### Do not add special handling for empty CV iterables

- Finding: F3 records empty split iterables as outside the proven domain and
  independent of the reported one-shot exhaustion bug.
- Proof obligation: PO-7 keeps this boundary explicit.
- Source decision: no SFS-specific empty-CV guard was added. If desired, that
  should be handled in shared CV validation, not as part of this targeted issue.

### Do not attempt to make consumed generators reusable across separate fits

- Finding: F4 records repeated fitting with the exact same already-consumed
  generator as underspecified and outside this issue's intent.
- Proof obligation: PO-7 limits the proof to a single fit using the supplied
  one-shot iterable.
- Source decision: no extra storage of materialized splits on the estimator was
  added.

## Formal Artifacts

The FVK artifacts are under `fvk/`. The formal core is
`fvk/mini-sfs-cv.k` and `fvk/sfs-cv-spec.k`; `fvk/PROOF.md` records the
`kompile`/`kast`/`kprove` commands but they were not executed, per the task
instructions.

## Test Decision

No test files were modified, per the benchmark instructions. The FVK guidance
recommends a nonregression test for a one-shot split generator if tests are
editable in a future context, but test removal or redundancy claims remain
conditioned on machine-checking the K proof.
