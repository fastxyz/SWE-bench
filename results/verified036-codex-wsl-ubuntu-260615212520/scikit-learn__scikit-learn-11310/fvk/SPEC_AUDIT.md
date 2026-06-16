# Spec Audit

Status: constructed for FVK audit, not machine-checked.

| Formal obligation | Intent match | Rationale |
| --- | --- | --- |
| `REFIT-TRUE` creates `refit_time_` after a successful final refit. | Pass | Directly matches evidence E1, E2, and E3. |
| `REFIT-TRUE` measures `TEnd - TStart` around the final estimator `fit`. | Pass | Matches E2 and aligns with in-repo timing convention E8. |
| Timing starts after clone/set-params. | Pass | This is not stated by the prompt, but E8 shows existing candidate `fit_time` excludes `set_params`; using the same boundary avoids a stronger, inconsistent timing definition. |
| `REFIT-FALSE` does not create a new attribute. | Pass | E6 says no final refit occurs under `refit=False`; mirroring `best_estimator_` availability is a named default-domain assumption. |
| Claims cover model_selection grid and randomized search through shared `BaseSearchCV.fit`. | Pass | E5 and source structure show both classes inherit the same final-refit tail. |
| Claims cover deprecated `sklearn.grid_search` duplicate after V2. | Pass | E7 shows a public duplicate final-refit path; V2 applies the same timing there. |
| The formal model abstracts away candidate search and scoring internals. | Pass | The requested property is the post-search final-refit attribute; frame conditions preserve the rest. |
| The proof is machine-checked. | Fail by design | The benchmark forbids running K tooling; artifacts are constructed, not machine-checked. This limits proof confidence but not the source-level intent finding. |
