# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbols

None.

`SequentialFeatureSelector.fit` keeps the same signature, return type, and public
attributes. The constructor parameter `cv` remains stored as `self.cv`.

## Changed Private/Internal Symbols

`SequentialFeatureSelector._get_best_new_feature_score` now accepts a local
`cv` argument. This method is private and has one in-repo callsite in
`_sequential.py`; V1 updated that callsite.

## Parameter Compatibility

`_parameter_constraints["cv"]` remains `["cv_object"]`, and `_CVObjects`
continues accepting integers, splitter objects, non-string iterables, and
`None`. This is required by evidence E5/E7.

## Behavioral Compatibility

- Integer and `None` CV values still route through `check_cv`, matching
  `cross_val_score` and SearchCV behavior.
- CV splitter objects still route through `check_cv`; because they have `split`,
  they are returned unchanged by `check_cv`.
- Non-string iterable CV values remain accepted. The behavior changes only in
  that they are materialized once per fit before repeated candidate scoring,
  which is the intended fix.
- No warning is added.

## Result

No compatibility blocker was found. V1 can stand unchanged on public API and
callsite compatibility grounds.
