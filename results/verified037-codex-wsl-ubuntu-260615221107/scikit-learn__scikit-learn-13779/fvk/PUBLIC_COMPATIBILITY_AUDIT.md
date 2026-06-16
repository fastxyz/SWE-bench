# Public Compatibility Audit

Changed public symbols:

- `_BaseVoting.fit(self, X, y, sample_weight=None)`, reached by
  `VotingClassifier.fit` and `VotingRegressor.fit`.

Compatibility checks:

| Surface | Status | Evidence |
|---|---|---|
| Method signatures | unchanged | No signature was changed in `_BaseVoting.fit`, `VotingClassifier.fit`, or `VotingRegressor.fit`. |
| Input estimator list semantics | compatible | `None` remains the existing dropped-estimator sentinel from docs and public tests. |
| Active unsupported estimator behavior with `sample_weight` | compatible | The unsupported-estimator ValueError is still raised for non-dropped estimators. |
| All-dropped behavior | compatible for valid names | The all-dropped ValueError remains reachable after filtering. |
| `estimators_` shape | compatible | Still contains fitted non-`None` estimators only. |
| `named_estimators_` shape | improved compatibility | It now aligns names with fitted non-`None` estimators, matching the documented "fitted sub-estimators" meaning. |
| Existing validation helpers | compatible | `_validate_names`, weights-length checks, and invalid-estimator-list checks are not relaxed. |
| Subclass/override dispatch | no new risk found | The changed method is a concrete internal base implementation; no new arguments or virtual method calls were added. |

No public callsite or override requires a signature update.
