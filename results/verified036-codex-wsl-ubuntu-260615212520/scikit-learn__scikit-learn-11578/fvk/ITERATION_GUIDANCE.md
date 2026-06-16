# Iteration Guidance

Status: constructed, not machine-checked.

## V2 decision

V1 stands unchanged. The FVK audit found the originally reported bug and the
broader constructor-parameter consistency gap, and both are already addressed
by the current source diff.

## Source guidance

- Keep the V1 constructor propagation in `_log_reg_scoring_path`.
- Keep the per-candidate `log_reg.C = C` assignment.
- Do not change `LogisticRegression.__init__` defaults for this issue.
- Do not change `_log_reg_scoring_path`'s signature or return shape.

## Test guidance

No tests were run and no test files were modified. When an execution
environment is available, useful public tests would exercise:

- `LogisticRegressionCV(scoring='neg_log_loss', multi_class='multinomial')`
  scores through multinomial `predict_proba`.
- A custom scorer that records `estimator.get_params()` for all shared
  constructor parameters.
- A custom scorer that records `estimator.C` for each candidate `C`.

Do not remove tests based on this FVK pass unless the recorded `kprove` commands
are run and return `#Top`.
