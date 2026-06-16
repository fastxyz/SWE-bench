# Public Evidence Ledger

Status: constructed for audit, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt / issue | "Whether to shuffle each stratification of the data before splitting into batches" | `shuffle=True` changes the sample order inside each class before fold assignment. | Encoded by C1 and PO2-PO4. |
| E2 | prompt / issue | "instead of shuffling samples within each stratum, the order of batches is shuffled" | The legacy behavior that preserves same class-pairing pattern is suspect and must not be preserved as a spec. | Finding F1. |
| E3 | prompt / issue | "1 is always paired with 11, 2 with 12, 3 with 13" | Equal-sized classes must not be forced to use the same per-class permutation. | Encoded by C1 and C2. |
| E4 | prompt / expected result | "I expect batches to be different when Shuffle is turned on for different random_state seeds" | The seed must influence the actual sample-to-fold assignment, not only the order in which fixed batches are yielded. | Encoded by C1; stronger all-seed uniqueness rejected in F2. |
| E5 | public hint | "we're shuffling each stratification in the same way (i.e, with the same random state)" | Root cause is reusing the same seed independently per class. | Finding F1; PO2. |
| E6 | public hint | "we should provide different splits when users provide different random state" | Fix should make different seeds capable of producing different split membership. | PO4; F2 clarifies collision limits. |
| E7 | source docstring | `random_state` is "Used when shuffle == True" | Avoid validating or consuming `random_state` on `shuffle=False`. | PO5. |
| E8 | public tests | repeated split calls with integer `random_state` should produce the same split | Integer seeds remain reproducible across `split` calls. | PO5. |
| E9 | public tests / helper source | `RandomState` instance split calls often produce different splits; `check_random_state(None)` returns the NumPy global singleton | Passing a stateful RNG object must still advance across calls/classes. | PO5. |
| E10 | source comments | per-class splitters use `KFold` to preserve class balance and trim oversized splits for under-populated classes | Keep the existing `KFold` fold-size and trim behavior. | PO5; no source change beyond RNG normalization. |
| E11 | compatibility search | no public override of `_make_test_folds`; public API exposes `StratifiedKFold` constructor and `split` | No signature or dispatch-shape change is needed. | Compatibility audit pass. |
