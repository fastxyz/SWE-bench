# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Expose warm_start in Isolation forest" | Add public constructor parameter. | Encoded by PO1 and K claim `IFOREST-EXPLICIT-WARM-START`. |
| E2 | `benchmark/PROBLEM.md` | "`sklearn.ensemble.IsolationForest` supports incremental addition of new trees with the `warm_start` parameter of its parent class, `sklearn.ensemble.BaseBagging`." | Do not duplicate fitting logic; pass the constructor value to `BaseBagging`. | Encoded by PO2. |
| E3 | `benchmark/PROBLEM.md` | "expose `warm_start` in `IsolationForest.__init__()`, default `False`" | Omitting `warm_start` yields `False`. | Encoded by PO1 and K claim `IFOREST-DEFAULT-WARM-START`. |
| E4 | `benchmark/PROBLEM.md` | Requested doc text: "When set to ``True``..." | Class docstring must describe the parameter. | Encoded by PO5. |
| E5 | `repo/sklearn/ensemble/bagging.py` | `BaseBagging.__init__` accepts `warm_start=False` and sets `self.warm_start = warm_start`; `_fit` branches on `self.warm_start`. | Passing the value to `BaseBagging` is sufficient to enable inherited behavior. | Implementation evidence supporting PO2 and PO3. |
| E6 | `repo/sklearn/ensemble/forest.py` | `RandomForestClassifier.__init__` lists `warm_start=False` after `verbose=0`; its docstring describes the same behavior. | Documentation wording and parameter placement should align with the named comparison estimator where compatible. | Encoded by PO4 and PO5. |
| E7 | Public API compatibility default | Existing constructor positional parameters are public API in this version because the signature is not keyword-only. | New optional parameter should not shift old positional arguments. | Generated Finding F1; fixed in V2 by appending `warm_start`. |
| E8 | Benchmark instruction | "Do not modify any test files" and "do not attempt to run tests, Python, or K framework tooling" | Verification is by static inspection and constructed proof artifacts only. | Reflected in `PROOF.md` and `reports/fvk_notes.md`. |
