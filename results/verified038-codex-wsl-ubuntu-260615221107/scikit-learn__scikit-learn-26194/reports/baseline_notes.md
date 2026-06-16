# Baseline Notes

## Root cause

`roc_curve` prepended an artificial threshold equal to `thresholds[0] + 1`
after `_binary_clf_curve` returned the observed scores in decreasing order.
That value is only used to add the initial `(fpr=0, tpr=0)` point, but for
probability estimates with scores in `[0, 1]` it can create a finite threshold
larger than 1. The artificial point is not an observed score, so representing
it as a finite score derived from `max(y_score)` is misleading.

## Changed files

`repo/sklearn/metrics/_ranking.py`

- Changed the artificial first ROC threshold from `thresholds[0] + 1` to
  `np.inf`, preserving the "no instances predicted" semantics without
  fabricating a finite score outside the input score scale.
- Updated the `roc_curve` return-value documentation and doctest-style example
  to describe and show the new `np.inf` sentinel.

`repo/doc/modules/model_evaluation.rst`

- Updated the ROC example threshold output to match the public behavior after
  the sentinel change.

## Assumptions and alternatives considered

I assumed the first threshold should remain a sentinel for the initial `(0, 0)`
ROC point and should not be treated as a real probability threshold. I therefore
used `np.inf`, which means no finite score can satisfy `score >= threshold`.

I considered clipping the first threshold to 1 when scores look like
probabilities, as suggested in the issue text. I rejected it because if an input
sample has score exactly 1, threshold 1 would predict that sample as positive
and would no longer correspond to the initial `(0, 0)` point.

I also considered using `np.nextafter(max_score, np.inf)`. I rejected it because
it still fabricates a finite threshold above 1 when `max_score == 1`, and it is
less explicit than the existing sentinel semantics.

No tests or project code were run, per the task constraints.
