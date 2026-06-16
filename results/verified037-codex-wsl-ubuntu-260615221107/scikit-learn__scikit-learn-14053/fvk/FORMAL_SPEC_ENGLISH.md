# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases the nontrivial claims in `fvk/export-text-spec.k`.

## EXPORT-SAFE-NAMED

Starting from `export(TREE, named(NFEATURES), MAXDEPTH)`, if the tree is a
well-formed fitted tree and every reachable split feature index is in
`[0, NFEATURES)`, traversal finishes with `badLookup == false`. The lookup trace
contains only split-node feature indices. In particular, `_tree.TREE_UNDEFINED`
is not a member of the lookup trace.

## EXPORT-SAFE-GENERIC

Starting from `export(TREE, noNames, MAXDEPTH)`, traversal does not index a
user-provided name list. Generic split labels are derived from split feature
indices, and leaf sentinels are not converted into generic labels because leaves
do not take the split branch.

## VISIT-LEAF-NO-LOOKUP

When the current node is a leaf and it is within the rendered depth, visiting
the node returns after emitting leaf text. It does not append to the feature-name
lookup trace and does not change `badLookup`.

## VISIT-SPLIT-LOOKUP

When the current node is a split node and it is within the rendered depth,
visiting the node first performs one feature-name lookup for that split feature,
then recursively visits the left and right children. The recursive proof
obligation requires both child subtrees to satisfy the same safety property.

## VISIT-TRUNCATED-NO-LOOKUP

When the current node is deeper than the rendered depth, visiting the node emits
the existing leaf-or-truncation output. It does not select a feature name for the
current node.

