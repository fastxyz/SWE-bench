# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Add joblib in show_versions" | `show_versions()` output must include a `joblib` dependency entry. | Encoded by OBL-1, OBL-3. |
| E2 | `benchmark/PROBLEM.md` | "joblib should be added to the dependencies listed in show_versions or added to the issue template when sklearn version is > 0.20." | One of the accepted remedies is to add `joblib` to the dependency list used by `show_versions()` for this version. | Encoded by OBL-1, OBL-4. |
| E3 | `benchmark/instance.json` | `"version": "0.22"` | The `> 0.20` condition in the issue applies to this task. | Encoded by OBL-1. |
| E4 | `repo/setup.py` | `install_requires=[..., 'joblib>={}'.format(JOBLIB_MIN_VERSION)]` | `joblib` is a runtime dependency in this tree and should be considered a main dependency for version reporting. | Encoded by OBL-1, OBL-2. |
| E5 | `repo/ISSUE_TEMPLATE.md` | `For scikit-learn >= 0.20: import sklearn; sklearn.show_versions()` | The issue template already delegates version collection to `show_versions()` for this version range. | Encoded by OBL-4. |
| E6 | `repo/sklearn/utils/_show_versions.py` | `_get_deps_info()` builds `deps_info` by iterating a static `deps` list. | Adding a module name to that list causes the generic import/version-or-None behavior to apply to it. | Implementation fact used by OBL-2 and the proof. |
| E7 | `reports/baseline_notes.md` | "added `joblib` to the dependency list used by `_get_deps_info()`" | V1 candidate implements the `show_versions()` remedy rather than the issue-template alternative. | Audited by F1-F3. |
