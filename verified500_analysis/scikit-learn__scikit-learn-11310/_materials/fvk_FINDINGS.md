# FVK Findings

Status: constructed for FVK audit, not machine-checked.

## Findings

### F1 - V1 satisfies the core model_selection intent

Classification: confirmed behavior.

Evidence: ledger entries E1, E2, E3, E4, E6, and proof obligation PO1.

Input/state: `sklearn.model_selection.GridSearchCV` or
`RandomizedSearchCV`, validated `refit=True` or a validated refit scorer key,
successful final full-data estimator fit.

Observed in V1: `BaseSearchCV.fit` starts `time.time()` immediately before
`self.best_estimator_.fit(...)` and stores `self.refit_time_` immediately after
the successful final fit.

Expected: after successful `fit`, the search object exposes `refit_time_` as
the elapsed final-refit duration in seconds.

Resolution: no further source change was needed in
`repo/sklearn/model_selection/_search.py`.

### F2 - V1 missed the deprecated duplicate search implementation

Classification: code completeness gap, fixed in V2.

Evidence: ledger entries E1, E5, E7, and proof obligations PO1 and PO4.

Input/state: `sklearn.grid_search.GridSearchCV` or
`RandomizedSearchCV`, `refit=True`, successful final full-data estimator fit.

Observed in V1: the deprecated duplicate `BaseSearchCV._fit` refit branch fit
the best estimator and assigned `best_estimator_`, but did not record
`refit_time_`.

Expected: while this public duplicate remains present and documents the same
final-refit behavior, the additive `refit_time_` attribute should be recorded
there as well.

Resolution: V2 imports `time`, times the duplicate final `best_estimator.fit`
call, stores `self.refit_time_`, and documents the attribute in both deprecated
search class docstrings.

### F3 - `refit=False` availability is intentionally unchanged

Classification: confirmed frame behavior.

Evidence: ledger entry E6 and proof obligation PO2.

Input/state: any covered search object with `refit=False`.

Observed: the refit branch is skipped, so `best_estimator_` and `refit_time_`
are unavailable.

Expected: no final full-data refit occurs, so there is no refit duration to
store. This mirrors the documented availability of `best_estimator_`.

Resolution: no source change.

### F4 - Proof is constructed, not machine-checked

Classification: proof confidence limitation.

Evidence: FVK verify honesty gate and benchmark prohibition on running K
tooling.

Observed: the artifacts include K semantics, claims, and exact commands, but
`kompile`, `kast`, and `kprove` were not run.

Expected: proof claims remain "constructed, not machine-checked" until a K
environment returns `#Top`.

Resolution: keep tests; do not remove tests based on this constructed proof
alone.

## No Open Code Findings

After V2, the FVK audit found no remaining source changes justified by the
public intent and proof obligations.
