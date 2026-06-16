# Baseline Notes

## Root cause

`export_text` eagerly built a `feature_names_` list by indexing the user-provided
`feature_names` with every value in `tree_.feature`. Leaf nodes store
`_tree.TREE_UNDEFINED` (`-2`) instead of a real feature index. With one input
feature, `feature_names[-2]` is out of range, so the exporter raised
`IndexError` before reaching the recursion logic that already knows to skip leaf
feature names.

## Changed files

`repo/sklearn/tree/export.py`

Removed the eager per-node feature-name expansion in `export_text`. The function
now resolves the split feature name only after confirming that the current node
is not `_tree.TREE_UNDEFINED`. This keeps leaf sentinels out of feature-name
indexing and preserves the existing output format for named and unnamed
features.

## Assumptions and alternatives

The intended validation remains that `feature_names`, when provided, must match
the fitted tree's feature count. I left that behavior unchanged.

I considered filtering `_tree.TREE_UNDEFINED` out of `tree_.feature` before
building the name list, but that would make the list no longer align with node
indices. I also considered changing the tree's stored leaf feature values, but
`TREE_UNDEFINED` is an internal sentinel used throughout the tree
implementation. The narrower fix is to avoid requesting feature names for leaf
nodes in `export_text`.
