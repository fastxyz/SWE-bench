# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`export_text` returns `IndexError` when there is single feature." | A valid one-feature tree with one feature name is in-domain and must not crash with `IndexError`. | Encoded by PO-1 and PO-2. |
| E2 | prompt code | `X = X[:, 0].reshape(-1, 1)` and `feature_names=['sepal_length']` | The feature-name list length is one because the fitted data has one feature. | Encoded by PO-1. |
| E3 | prompt hint | "`-2` indicates a leaf node, which does not split on a feature" | `TREE_UNDEFINED` is not a feature index; it marks leaves. | Encoded by PO-2 and PO-4. |
| E4 | prompt hint | "export_tree should never be accessing the feature name for a leaf" | Feature-name indexing is permitted only after proving the node is a split node. | Encoded by PO-2. |
| E5 | source docstring | "A list of length n_features containing the feature names. If None generic names will be used (`feature_0`, `feature_1`, ...)." | Named split nodes use the provided name; unnamed split nodes use generic names. | Encoded by PO-3. |
| E6 | source code | Existing validation checks `feature_names is not None` and length mismatch before traversal. | Invalid name-list length remains an error; the fix should not mask it. | Encoded by PO-1 and compatibility audit. |
| E7 | implementation fact | V1 indexes `feature_names[feature]` inside `if tree_.feature[node] != _tree.TREE_UNDEFINED`. | Candidate implementation localizes indexing to split nodes. | Checked by PO-2 and proof. |
| E8 | implementation fact | Truncation and leaf branches do not use `name`. | Non-split branches cannot trigger the reported named-feature index error. | Checked by PO-4. |

