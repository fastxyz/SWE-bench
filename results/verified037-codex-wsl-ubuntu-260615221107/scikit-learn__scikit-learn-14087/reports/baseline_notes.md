# Baseline Notes

## Root cause

`LogisticRegressionCV.fit` resolves `multi_class='auto'` to an effective
strategy with `_check_multi_class`, but the `refit=False` coefficient selection
path still checked `self.multi_class`. For binary classification, and for
`solver='liblinear'`, the effective strategy is OvR while `self.multi_class`
can remain `'auto'`. The no-refit path then treated the OvR coefficient path as
if it were multinomial and indexed a 3D array with four indices, raising the
reported `IndexError`.

The same no-refit block also always averaged selected `l1_ratios_`. For
non-elastic-net penalties, `l1_ratios_` is `[None]`, so once the coefficient
indexing is corrected the default `penalty='l2'` case from the issue should
record `None` instead of trying to average a nonexistent elastic-net parameter.

## Files changed

- `repo/sklearn/linear_model/logistic.py`
  - In the `refit=False` path, use the resolved local `multi_class` value when
    deciding whether coefficient paths are OvR or multinomial.
  - Only compute an averaged best `l1_ratio_` when the active penalty is
    elastic-net; otherwise append `None`, matching the absence of an
    elastic-net mixing parameter.
  - Convert `l1_ratios_` to an array at the selection point so accepted
    list-like `l1_ratios` can be indexed by the per-fold best-index array.

## Assumptions and alternatives considered

- I assumed the correct behavior for `multi_class='auto'` is to follow the
  already-computed effective `multi_class` value throughout `fit`, because the
  earlier shape construction and the refit path already use that value.
- I considered changing the stored estimator parameter from `'auto'` to the
  resolved value, but rejected it because estimator parameters should preserve
  constructor input for introspection and cloning.
- I considered reshaping OvR coefficient paths to satisfy the multinomial
  indexing branch, but rejected it because the branch choice was the actual
  error and reshaping would obscure the intended data layout.
- I did not modify tests, per the task instructions, and did not run tests or
  project code in this session.
