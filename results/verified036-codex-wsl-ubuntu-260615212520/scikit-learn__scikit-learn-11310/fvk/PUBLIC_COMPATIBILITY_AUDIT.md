# Public Compatibility Audit

Status: constructed for FVK audit, not machine-checked.

## Changed Public Symbols

`sklearn.model_selection.GridSearchCV.fit`
`sklearn.model_selection.RandomizedSearchCV.fit`
`sklearn.grid_search.GridSearchCV.fit`
`sklearn.grid_search.RandomizedSearchCV.fit`

The method signatures are unchanged. The constructor signatures are unchanged.
No virtual method is called with a new argument. The final estimator `fit` call
uses the same arguments as before in both `y is not None` and `y is None`
branches.

## New Attribute

`refit_time_` is added after a successful final refit. This is additive public
state and does not change existing attributes. It is intentionally absent when
`refit=False`, matching the documented availability pattern for
`best_estimator_`.

## Callsite and Override Audit

Searches of the source tree show `GridSearchCV` and `RandomizedSearchCV` in
`repo/sklearn/model_selection/_search.py` inherit the shared `BaseSearchCV.fit`
implementation. The deprecated `repo/sklearn/grid_search.py` has a separate
`BaseSearchCV._fit` implementation and was patched separately in V2.

No public callsite requires updates because this change does not alter a call
signature, return type, input type, or dispatch protocol.

## Compatibility Finding

No unresolved compatibility blockers remain.
