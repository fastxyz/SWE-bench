# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue | "HistGradientBoostingClassifier does not work with string target when early stopping turned on" | Classifier early stopping must support string class labels. | Encoded in I1 and claims `HGB-CLASSIFIER-*`. |
| E2 | prompt issue | "The scorer used under the hood during early stopping is provided with `y_true` being integer while `y_pred` are original classes (i.e. string)." | The failing boundary is the scorer call, not the loss/training representation. | Encoded in I2 and finding F1. |
| E3 | prompt issue | "Expected Results: No error is thrown" for `HistGradientBoostingClassifier(n_iter_no_change=10).fit(X, y)` where `y` is `['x', 'y']`. | The reproducer is in-domain for classifier early stopping. | Encoded in I1, PO-C1, PO-S1, PO-S2. |
| E4 | prompt issue potential resolution | Suggested conversion `self.classes_[y_small_train.astype(int)]` and `self.classes_[y_val.astype(int)]` before scorer calls. | Internal class-code targets should be converted back to public class labels before scorer calls. | Encoded in I2 and claims `HGB-GET-Y-CLASSIFIER`, `HGB-SCORER-CLASSIFIER-VAL`, `HGB-SCORER-CLASSIFIER-NOVAL`. |
| E5 | source `gradient_boosting.py` | `y = self._encode_y(y)` at fit entry, and classifier `_encode_y` uses `LabelEncoder`. | The internal training representation for classifier targets is encoded class codes. | Encoded in D2 and PO-C1. |
| E6 | source `gradient_boosting.py` | `predict` returns `self.classes_[encoded_classes]`. | Classifier public predictions are original class labels. | Encoded in I2 and PO-C1. |
| E7 | source/scorer docs | `check_scoring` returns a callable with signature `scorer(estimator, X, y)`. `_PredictScorer` calls `estimator.predict(X)` and compares against `y_true`. | Scorer `y` should match the public prediction representation. | Encoded in I2 and SPEC_AUDIT A2. |
| E8 | source `gradient_boosting.py` | `scoring == 'loss'` uses `_check_early_stopping_loss` with loss objects and raw predictions. | Loss scoring remains internal and encoded; only scorer-based early stopping needs public-label conversion. | Encoded in I3 and PO-L1. |
| E9 | source tests | Existing public early-stopping tests use numeric classification labels and regression labels. | Public tests cover early stopping but not the reported string-label mismatch. | Recorded as test gap F4. |
| E10 | source search | `_get_y_for_scorer` is private and only called/overridden in `gradient_boosting.py`. | The V1 helper does not change a public API or external dispatch contract. | Encoded in compatibility audit C1-C3. |
