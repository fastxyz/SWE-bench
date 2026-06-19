# scikit-learn__scikit-learn-11310 — FVK analysis

- **Verdict:** B_COMPLETENESS (low value) — in the file that matters (`model_selection/_search.py`) baseline and fvk are byte-identical and match gold; fvk's only net change replicates the same `refit_time_` timing into the **deprecated** `sklearn/grid_search.py` duplicate, which the human fix deliberately left untouched.
- **Pitch-worthiness (1-5):** 2

## Summary
The issue: expose `refit_time_` (time spent refitting the best estimator) on search CV objects. In `model_selection/_search.py`, baseline and fvk are identical and semantically match gold (gold uses a named temp; baseline/fvk inline it).

fvk additionally adds the same timing to `sklearn/grid_search.py` — but that module is the deprecated pre-0.18 search implementation (old `_fit` signature, scheduled for removal in 0.20). The gold fix did **not** touch it; the maintainers deliberately left the dying module alone.

## Verification
The test suite only references `model_selection/tests/test_search.py`; nothing imports/exercises `grid_search.py`. The only behavioral difference: `sklearn.grid_search.GridSearchCV(...).fit(...).refit_time_` exists under fvk, raises `AttributeError` under baseline — but only on the deprecated module.

**GOLD_MATCH: partial.** A coherent completeness extension, but into dead code the real fix intentionally skipped — low value, slight scope-creep. CONFIDENCE: high.
