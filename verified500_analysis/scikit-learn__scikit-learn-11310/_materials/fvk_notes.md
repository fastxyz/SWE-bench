# FVK Notes

## Decisions

### Kept `repo/sklearn/model_selection/_search.py` V1 behavior

FVK finding F1 confirms that V1 satisfies the core public issue for
`sklearn.model_selection`: after a successful final refit, the code records
`self.refit_time_` as elapsed wall-clock time around the final
`self.best_estimator_.fit(...)` call. This discharges PO1 and PO3 for the
issue's example module and preserves PO5 because no signature, return shape,
`cv_results_`, or estimator-dispatch behavior changes.

The FVK audit did not justify moving the timer earlier to include cloning or
`set_params`; PO3 explicitly keeps the timing boundary aligned with existing
cross-validation `fit_time`, which starts after parameter assignment.

### Patched `repo/sklearn/grid_search.py`

FVK finding F2 identified a duplicate public final-refit path in deprecated
`sklearn.grid_search`. Although the issue example uses `sklearn.model_selection`,
the deprecated module still defines `GridSearchCV`, `RandomizedSearchCV`, and a
separate `BaseSearchCV._fit` with the same documented final-refit behavior.
PO4 requires both public search implementations to satisfy the same refit-time
obligation while both exist in the source tree.

The V2 patch imports `time`, starts the timer immediately before the deprecated
duplicate `best_estimator.fit(...)`, stores `self.refit_time_` after successful
fit, and documents `refit_time_` in both deprecated search class docstrings.
This discharges PO1, PO3, PO4, and PO6 for the duplicate path without changing
public call signatures or existing fit arguments, preserving PO5.

### Left `refit=False` behavior unchanged

FVK finding F3 confirms that no refit means no refit duration. PO2 requires the
attribute to remain unavailable when the final refit branch does not execute,
matching the documented availability pattern for `best_estimator_`.

### Did not edit tests or run verification

FVK finding F4 records that the proof is constructed, not machine-checked. The
benchmark prohibits running tests, Python, or K tooling, so I emitted the exact
`kompile`, `kast`, and `kprove` commands in the artifacts but did not execute
them. No test files were modified.

## Result

After V2, the source satisfies all current FVK proof obligations:

- PO1: successful final refit stores elapsed time;
- PO2: `refit=False` does not create timing state;
- PO3: timing boundary matches existing fit-time convention;
- PO4: both public search implementations are covered;
- PO5: public compatibility is preserved;
- PO6: public docs list the new attribute.
