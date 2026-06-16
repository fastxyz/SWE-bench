# FVK Findings

Status: constructed, not machine-checked. These findings are based on public
intent, static source inspection, and the constructed proof obligations.

## F1: Resolved Original Scorer Representation Bug

Input: classifier early stopping with `classes_ = ["x", "y"]`,
`y_small_train = [0, 1]` internally, and predictions returning `["x", "y"]`.

Observed before V1: `_check_early_stopping_scorer` passed encoded numeric
`y_true` directly to `self.scorer_`, while classifier `predict` returned public
class labels. Accuracy scoring could then compare mixed numeric/string labels,
matching the reported `TypeError`.

Expected from intent: scorer `y_true` must be public class labels when
classifier predictions are public class labels.

V1 status: resolved. `_check_early_stopping_scorer` calls
`self._get_y_for_scorer(...)`, and `HistGradientBoostingClassifier` maps
internal codes through `classes_`.

Proof links: PO-C1, PO-S1, PO-S2.

## F2: No Remaining Scorer Callsite Gap Found

Input classes: initial early-stopping score before the first tree and the
per-iteration early-stopping score after trees are added, each with either
validation data enabled or disabled.

Observed in V1: both source callsites enter the same
`_check_early_stopping_scorer` method, and that method applies
`_get_y_for_scorer` to the training target and, when present, the validation
target.

Expected from intent: every scorer-based early-stopping call sees consistent
target representation.

V1 status: confirmed. No additional code edit is justified.

Proof links: PO-S1, PO-S2, PO-S3.

## F3: Regression and Loss Paths Preserved

Input classes: `HistGradientBoostingRegressor` with scorer-based early stopping
and either estimator with `scoring='loss'`.

Observed in V1: the base helper returns targets unchanged, preserving
regression. The loss path calls `_check_early_stopping_loss` and is not routed
through `_get_y_for_scorer`.

Expected from intent: only classifier scorer targets need public-label
conversion; internal losses must continue using encoded targets.

V1 status: confirmed. No additional code edit is justified.

Proof links: PO-B1, PO-L1.

## F4: Public Test Gap

Input class: string labels with `HistGradientBoostingClassifier` and
`n_iter_no_change` set so scorer-based early stopping runs.

Observed public tests: early-stopping classification tests use numeric labels.
They cover scorer/loss and validation/no-validation combinations, but not the
reported mixed string-label failure.

Expected from intent: a regression test should cover string labels on the
scorer path.

Status: test gap only. The task forbids modifying tests, so no test file was
changed. A future public test should exercise the reproducer or an equivalent
string-label scorer case.

Proof links: PO-T1.

## F5: Proof Is Constructed, Not Machine-Checked

Input: the K artifacts in `fvk/mini-hgb-scorer.k` and
`fvk/hgb-scorer-spec.k`.

Observed: this environment forbids running K tooling, so `kompile`, `kast`,
and `kprove` were not executed.

Expected from FVK honesty gate: mark the proof as constructed, not
machine-checked, and condition any test-redundancy recommendation on a later
machine check.

Status: residual verification risk, not a source-code bug.

Proof links: PO-V1.
