# Intent Spec

Status: constructed, not machine-checked.

## Scope

The audited unit is `sklearn.tree.export.export_text`, specifically the
feature-name selection behavior inside its recursive tree traversal. The full
rendering format is not reimplemented here; the FVK model keeps the observable
that matters for this issue: which tree nodes may trigger feature-name indexing.

## Intent-derived obligations

I1. For a fitted decision tree with one input feature and
`feature_names=['sepal_length']`, `export_text` must return a text report rather
than raising `IndexError`.

Source: `benchmark/PROBLEM.md`, description and reproduction.

I2. `feature_names`, when provided, names input features and has length equal to
the fitted tree's feature count.

Source: `export_text` docstring and existing validation in
`repo/sklearn/tree/export.py`.

I3. Leaf nodes do not split on a feature and therefore must not request a feature
name.

Source: public issue discussion: "`-2` indicates a leaf node" and "export_tree
should never be accessing the feature name for a leaf."

I4. Split nodes with user-provided names must render the name at their split
feature index; split nodes without user-provided names must render
`feature_<index>`.

Source: `export_text` docstring and example.

I5. Existing validation for `max_depth`, `spacing`, `decimals`, and
feature-name length is frame behavior for this fix.

Source: public function code and nearby public tests; none of these are reported
as buggy in the issue.

## Domain assumptions

D1. The tree is fitted. `check_is_fitted(decision_tree, 'tree_')` enforces this
before traversal.

D2. For fitted scikit-learn tree objects, reachable split nodes use valid feature
indices in `[0, tree_.n_features)`, while leaf nodes use
`_tree.TREE_UNDEFINED` (`-2`).

D3. The FVK proof is partial correctness: it shows that, if traversal returns,
named-feature indexing is only attempted for valid split nodes. It does not
prove traversal termination for arbitrary malformed tree arrays.

