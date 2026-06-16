# Public Evidence Ledger

Status: all entries are from allowed public inputs or source files in `repo/`.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`RepeatedKFold` and `RepeatedStratifiedKFold` do not show correct `__repr__` string." | Both repeated splitter classes need a meaningful `repr`. | Encoded in O1, C1. |
| E2 | `benchmark/PROBLEM.md` | Expected default values show `n_splits=5`, `n_repeats=10`, `random_state=None`. | Default repeated splitter repr must include those parameter values. | Encoded in O2, C2, C3. |
| E3 | `benchmark/PROBLEM.md` | Actual output is `<sklearn.model_selection._split.RepeatedKFold object at ...>`. | Default object identity repr is the defect and must not remain. | Encoded in O1, F1. |
| E4 | public hint in `benchmark/PROBLEM.md` | "`__repr__` is not defined in the `_RepeatedSplit` class..." | Add repr behavior at the repeated-splitter base, not only one subclass. | Encoded in O1. |
| E5 | public hint in `benchmark/PROBLEM.md` | "`n_splits` ... is stored in the `cvargs` class attribute." | `_build_repr` must recover missing constructor parameters from `cvargs`. | Encoded in O2. |
| E6 | `repo/sklearn/model_selection/_split.py` | `BaseCrossValidator.__repr__` and `BaseShuffleSplit.__repr__` both return `_build_repr(self)`. | Repeated splitters should reuse the same helper unless public intent requires a special format. | Encoded in O1, O5. |
| E7 | `repo/sklearn/model_selection/tests/test_split.py` | `KFold` expected repr is `KFold(n_splits=2, random_state=None, shuffle=False)`. | Existing cross-validator repr order follows sorted key order, not constructor order. | Encoded in O5. |
| E8 | `repo/sklearn/base.py` and `_split.py` | `_pprint` iterates `sorted(params.items())`; `_build_repr` sorts constructor parameter names. | The representation order convention is sorted by parameter name. | Encoded in O5. |
| E9 | `repo/sklearn/model_selection/_split.py` | `RepeatedKFold.__init__` and `RepeatedStratifiedKFold.__init__` pass `n_splits=n_splits` through `super().__init__(..., **cvargs)`. | `n_splits` is absent as a direct attribute and must be resolved through `cvargs`. | Encoded in O2, C2, C3. |
| E10 | task instructions | "Do not modify any test files" and "do not attempt to run tests, Python, or K framework tooling." | The audit may write artifacts and source fixes only; it must not execute or edit tests. | Satisfied; no test files or commands executed. |

