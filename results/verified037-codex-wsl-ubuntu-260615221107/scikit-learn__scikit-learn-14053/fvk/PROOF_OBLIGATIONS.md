# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Feature-name length guard

Source: E2, E5, E6.

Obligation: If `feature_names is not None`, traversal starts only when
`len(feature_names) == tree_.n_features`; otherwise the existing `ValueError`
is raised before any tree node is visited.

V1 status: discharged by unchanged validation at
`repo/sklearn/tree/export.py:873`.

## PO-2: Split-only named lookup

Source: E1, E3, E4, E7.

Obligation: User-provided feature names are indexed only in states satisfying
`tree_.feature[node] != _tree.TREE_UNDEFINED`.

V1 status: discharged by the guard at `repo/sklearn/tree/export.py:925`; the
only `feature_names[feature]` expression is inside that branch.

## PO-3: Correct split label selection

Source: E5.

Obligation: For a split node, use `feature_names[feature]` when names are
provided and `"feature_{}".format(feature)` when names are not provided.

V1 status: discharged by `repo/sklearn/tree/export.py:926-930`.

## PO-4: Leaf and truncation branches do not select feature names

Source: E3, E4, E8.

Obligation: Leaf handling and depth-truncation handling do not index
`feature_names` and do not derive generic feature labels from
`TREE_UNDEFINED`.

V1 status: discharged by the `else:  # leaf` branch at
`repo/sklearn/tree/export.py:944` and truncation branch after the split/leaf
logic. Neither branch contains a feature-name lookup.

## PO-5: One-feature reported case

Source: E1, E2, E3.

Obligation: For a fitted one-feature tree with `feature_names` length one,
reachable split nodes with feature index `0` use `feature_names[0]`; reachable
leaf nodes with feature sentinel `-2` do not index the list.

V1 status: discharged by PO-1 through PO-4.

## PO-6: No public API or validation regression

Source: E5, E6.

Obligation: Public signature, return type, and existing validation errors remain
unchanged.

V1 status: discharged by the compatibility audit. No source changes are needed
after V1.

## PO-7: Formal adequacy

Source: FVK method.

Obligation: The formal model must distinguish the original defect from the V1
behavior. The observable therefore includes a lookup trace and a `badLookup`
flag.

V1 status: discharged by `fvk/mini-export-text.k` and
`fvk/export-text-spec.k`. The model is reduced, but it preserves the relevant
pass/fail property.

