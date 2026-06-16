# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Retrieving time to refit the estimator in BaseSearchCV" | The public behavior belongs to `BaseSearchCV` search fitting, not to a private helper alone. | Encoded in the reduced final-refit-tail spec. |
| E2 | prompt | "time it takes to refit the best model on the full data after doing grid/random search" | The measured interval is the final fit of the selected best estimator on the full input data, after candidate search. | Encoded in PO1 and K claim `REFIT-TRUE`. |
| E3 | prompt | "have an attribute `refit_time_`" | Store the final refit duration as an estimator attribute named exactly `refit_time_`. | Encoded in source and K postcondition. |
| E4 | prompt | Example reads `cv_results_['mean_fit_time']` and `cv_results_['mean_score_time']` before asking for a separate attribute. | Do not add per-candidate `cv_results_` entries for the final refit duration. | Encoded as a frame obligation. |
| E5 | prompt | "grid/random search" | Both `GridSearchCV` and `RandomizedSearchCV` should expose the behavior through their shared search base. | Encoded for model_selection and deprecated duplicate. |
| E6 | source docs | `refit : ... Refit an estimator using the best found parameters on the whole dataset.` in `repo/sklearn/model_selection/_search.py` | `refit=True`/validated refit string implies a final full-data refit; `refit=False` does not. | Encoded in `REFIT-TRUE` and `REFIT-FALSE`. |
| E7 | source docs | Deprecated `repo/sklearn/grid_search.py` still documents `refit : boolean ... Refit the best estimator with the entire dataset.` | The deprecated public duplicate has the same observable final-refit concept while it remains present. | Produced Finding F2 and V2 patch. |
| E8 | implementation | `_fit_and_score` starts timing after `set_params` and before fitting/scoring split data. | Use `time.time()` and start after `clone(...).set_params(...)`, immediately before the final estimator `fit`. | Encoded as a default-domain timing alignment. |
| E9 | compatibility | No public method signature or virtual dispatch shape is changed by adding an attribute after fit. | Existing callsites and overrides remain compatible. | Encoded in compatibility audit. |
