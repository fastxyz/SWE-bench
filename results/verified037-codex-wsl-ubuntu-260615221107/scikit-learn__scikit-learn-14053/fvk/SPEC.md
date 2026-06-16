# FVK Spec

Status: constructed, not machine-checked.

## Target

`repo/sklearn/tree/export.py::export_text`, focusing on the recursive
`print_tree_recurse` branch that selects feature names for displayed split
rules.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical entries are E1 through E4:
the public issue makes one-feature named export an in-domain behavior, and the
public discussion identifies `_tree.TREE_UNDEFINED` (`-2`) as a leaf sentinel
that must not be used to request a feature name.

## Contract

For any fitted tree in the audited domain:

1. If `feature_names is not None`, `len(feature_names) == tree_.n_features`.
   Otherwise `export_text` raises the existing `ValueError` before traversal.
2. During traversal, a user-provided feature name is indexed only when
   `tree_.feature[node] != _tree.TREE_UNDEFINED`.
3. For every reachable split node, the selected display name is:
   - `feature_names[tree_.feature[node]]` when `feature_names` is provided;
   - `"feature_{}".format(tree_.feature[node])` otherwise.
4. For every reachable leaf node, `export_text` emits leaf value/class text and
   performs no feature-name lookup.
5. For truncated branches, `export_text` emits the existing truncation text and
   performs no feature-name lookup at the truncated node.

## Preconditions

P1. The estimator is fitted and has `tree_`.

P2. The tree object satisfies scikit-learn's fitted-tree shape invariant:
reachable split-node feature indices are in `[0, tree_.n_features)`, and leaf
nodes use `_tree.TREE_UNDEFINED`.

P3. If `feature_names` is provided, its length equals `tree_.n_features`.

These are intent-derived or existing public API preconditions. P2 is the tree
implementation invariant used by the exporter and graph exporters.

## Postcondition

For the reported one-feature case, every split node indexes
`feature_names[0]`, every leaf node skips feature-name indexing, and the function
can continue to construct the report instead of raising `IndexError` from
`feature_names[-2]`.

## Frame Conditions

F1. Validation behavior for negative `max_depth`, nonpositive `spacing`,
negative `decimals`, and incorrect `feature_names` length is unchanged.

F2. Text formatting, threshold formatting, class/value formatting, child
traversal order, and truncation wording are unchanged by this audit.

F3. Public function signature and return type are unchanged.

## Formalization Note

The K artifacts model a reduced exporter, not full Python. The abstraction is
property-complete for this issue because it preserves the pass/fail axis:
whether a named-feature lookup can be attempted with `_tree.TREE_UNDEFINED`.
The model has split nodes, leaf nodes, optional feature-name length, recursive
visitation, depth truncation, a lookup trace, and a `badLookup` flag.

