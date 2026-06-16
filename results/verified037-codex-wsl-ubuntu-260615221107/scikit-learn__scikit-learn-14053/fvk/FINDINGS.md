# Findings

Status: constructed, not machine-checked.

## F-1: Resolved code bug, leaf sentinel used as a feature-name index

Evidence: E1, E3, E4, PO-2, PO-5.

Input: a fitted one-feature decision tree with `feature_names=['sepal_length']`
and reachable leaf nodes whose `tree_.feature[node]` is `_tree.TREE_UNDEFINED`
(`-2`).

Observed before V1: the old eager list comprehension attempted
`feature_names[-2]` while building names for every node, which raises
`IndexError` for a one-item list.

Expected: leaves do not split on features, so the exporter should not request a
feature name for leaf nodes.

V1 result: resolved. The only user-provided feature-name lookup is now in the
split-node branch.

## F-2: No new source bug found in V1 for the audited intent

Evidence: PO-1 through PO-6.

Input: any fitted tree satisfying the scikit-learn tree invariant, with
`feature_names` either `None` or length `tree_.n_features`.

Observed in V1 by static control-flow audit: split nodes select one label using
their split feature; leaf and truncation branches do not select feature names.

Expected: exactly the behavior in I2 through I5.

V1 result: no additional code change is justified by the FVK audit.

## F-3: Residual proof limitation, not a code bug

Evidence: PO-7 and `PROOF.md`.

The proof is constructed over a reduced mini semantics and was not run through
`kompile` or `kprove`. It establishes the intended control-flow argument only
under the fitted-tree invariants listed in `SPEC.md`. This is an honesty-gate
limitation; it does not justify withholding the V1 fix, and it does not surface
a new production-code change.

## Proof-derived findings from `/verify`

No proof-derived code bug was found. The constructed proof's only required side
conditions are the public fitted-tree invariants and the existing
feature-name-length guard. Both are already present in the exporter contract or
tree object model.

