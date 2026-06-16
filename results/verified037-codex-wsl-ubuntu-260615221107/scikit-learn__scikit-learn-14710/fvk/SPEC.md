# FVK Spec

Status: constructed, not machine-checked. K commands are listed in
`PROOF.md`; they were not executed in this environment.

## Scope

The verified unit is the target-representation boundary in
`BaseHistGradientBoosting._check_early_stopping_scorer` and the helper
`_get_y_for_scorer`. This is the boundary that passes `y` to
`self.scorer_(self, X, y)` during early stopping when `scoring != 'loss'`.

The model abstracts away tree construction, prediction values, and metric
arithmetic. Those are not the reported defect. The observable preserved by the
model is the exact representation of the target vector passed to the scorer:
internal classifier codes versus public class labels.

## Public Intent Ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical obligations:

- E1-E4: classifier scorer calls must not compare integer-coded `y_true` with
  string/public-label predictions. Encoded classifier targets must be mapped
  through `classes_` before scorer calls.
- E5-E6: classifier fitting encodes targets, while `predict` returns
  `classes_[encoded_classes]`.
- E7: scorer callables consume `(estimator, X, y)` and compare `y` to public
  predictions or probabilities.
- E8: the loss path is internal and should continue using encoded targets.
- E10: the V1 helper is private and only internally dispatched.

## Preconditions

P1. For classifier claims, each encoded target value is integer-valued and is a
valid index into `classes_`. This follows from `LabelEncoder.fit_transform`
before the values are cast to `Y_DTYPE`.

P2. The audited path is scorer-based early stopping: `n_iter_no_change` has
enabled early stopping and `scoring != 'loss'`.

P3. The proof is partial correctness over target representation. It assumes
the scorer call is reached and does not prove fitting termination.

## Postconditions

S1. Base/regression `_get_y_for_scorer(y)` returns `y` unchanged.

S2. Classifier `_get_y_for_scorer(y)` returns `classes_[y.astype(np.intp)]`.
Equivalently, every encoded code `i` becomes the public label `classes_[i]`.

S3. `_check_early_stopping_scorer` passes `_get_y_for_scorer(y_small_train)` to
the training scorer call.

S4. If validation data is used, `_check_early_stopping_scorer` passes
`_get_y_for_scorer(y_val)` to the validation scorer call.

S5. If validation data is not used, no validation scorer call is made.

S6. `scoring='loss'`, gradient updates, raw predictions, public estimator
signatures, and prediction outputs are unchanged.

## Formal Core

- `mini-hgb-scorer.k` models the small scorer-boundary fragment.
- `hgb-scorer-spec.k` contains the reachability claims for base identity,
  classifier decoding, validation scoring, and train-only scoring.

The formal model has a discriminator for the defect: a failing pre-fix instance
maps internal `codes(0, 1)` and public `labels("x", "y")` to different
observables, while V1 maps the scorer target to `labels("x", "y")`.
