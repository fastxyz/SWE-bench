# Public Compatibility Audit

Status: constructed for FVK audit; not machine-checked.

## Changed Public Symbol

`sklearn.impute.IterativeImputer.__init__`

V1 adds keyword-only parameter `fill_value=None` after
`initial_strategy="mean"`.

Compatibility result: pass.

Reasoning:

- The new parameter has a default, so existing constructor calls remain valid.
- The parameter is keyword-only because it is after `*`, matching the existing
  constructor style.
- V1 stores `self.fill_value`, so scikit-learn estimator introspection through
  `get_params`/`set_params` can see the parameter.
- `_parameter_constraints` includes `"fill_value": "no_validation"`, matching
  `SimpleImputer` and avoiding an API-level rejection of `np.nan`.

## Public Call Sites

No required source callsite update is identified for compatibility because the
new parameter is optional. Existing public code that does not pass
`fill_value` continues to receive `None`.

## Internal Producer/Consumer Shape

The internal producer is `IterativeImputer._initial_imputation`. The internal
consumer is `SimpleImputer(...)`.

Compatibility result: pass.

Reasoning:

- `SimpleImputer` already accepts a `fill_value` keyword.
- Passing `None` preserves the previous default behavior.
- Passing `np.nan` is accepted by `SimpleImputer` for numerical input because
  `np.nan` is a real-valued float; estimator-level handling remains delegated.

## Subclass and Override Risk

No virtual dispatch signature was changed. V1 does not call a user-overridable
method with a new keyword argument. The new keyword is passed to the concrete
`SimpleImputer` constructor.

