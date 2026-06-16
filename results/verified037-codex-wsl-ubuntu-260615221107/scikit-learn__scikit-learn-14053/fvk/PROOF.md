# Constructed Proof

Status: constructed, not machine-checked. No K tooling was run.

## Claims

The proof targets the claims in `fvk/export-text-spec.k` over the reduced
semantics in `fvk/mini-export-text.k`.

The main claim is `EXPORT-SAFE-NAMED`: for any fitted-tree model whose split
feature indices are in range for the provided feature-name length, the traversal
finishes with `badLookup == false` and the lookup trace does not contain `-2`.

## Proof sketch

1. `export(TREE, named(NFEATURES), MAXDEPTH)` initializes the names, depth,
   lookup trace, and `badLookup` flag, then rewrites to `visit(TREE, 1)`.
2. Case split on the node reached by `visit`.
3. If `DEPTH > MAXDEPTH + 1`, the truncation rule fires. It returns without
   `lookupName`, so lookup trace and `badLookup` are unchanged. This discharges
   `VISIT-TRUNCATED-NO-LOOKUP`.
4. If the node is `leaf`, the leaf rule fires. It returns without
   `lookupName`, so lookup trace and `badLookup` are unchanged. This discharges
   `VISIT-LEAF-NO-LOOKUP`.
5. If the node is `split(FEATURE, LEFT, RIGHT)` and within the rendered depth,
   the split rule performs exactly one `lookupName(FEATURE)` before recursing.
   Under the fitted-tree invariant and `FEATURE < NFEATURES`, the safe named
   lookup rule fires and appends `FEATURE` to the trace without setting
   `badLookup`.
6. The recursive child visits appeal to the same safety claim as circularities
   on the left and right subtrees. Guardedness is supplied by the genuine split
   rewrite and lookup step before either recursive appeal.
7. Because every recursive path is either truncation, leaf, or split with an
   in-range feature index, no path reaches the bad lookup rule. Therefore
   `badLookup` remains `false`, and since leaves do not call `lookupName`, the
   lookup trace cannot contain `_tree.TREE_UNDEFINED` (`-2`).

This exactly distinguishes V1 from the pre-fix control flow: the pre-fix eager
list comprehension effectively performed `lookupName(tree_.feature[node])` for
all nodes before recursion. On a one-feature tree with a leaf node, that includes
`lookupName(-2)` under `named(1)`, which reaches the bad lookup rule.

## Source correspondence

The split case corresponds to `repo/sklearn/tree/export.py:925-943`, where V1
checks `tree_.feature[node] != _tree.TREE_UNDEFINED` before reading
`feature_names[feature]`.

The leaf case corresponds to `repo/sklearn/tree/export.py:944-945`, which calls
`_add_leaf` without accessing `feature_names`.

The length precondition corresponds to
`repo/sklearn/tree/export.py:873-877`.

## Residual risk

This is a partial-correctness proof over a reduced model. It does not prove
termination for arbitrary malformed tree arrays, exact report string formatting,
or NumPy/Python implementation details outside the modeled lookup control flow.
Those are frame conditions because V1 does not change them.

## Test-redundancy recommendation

No tests are modified. After machine-checking returns `#Top`, focused tests that
only assert one-feature named export does not raise `IndexError` would be
subsumed by `EXPORT-SAFE-NAMED`. Integration tests for exact report formatting,
invalid-parameter errors, regressors/classifiers, and traversal order should be
kept because this reduced proof does not cover the full string renderer.

## Commands to machine-check later

These commands are recorded only; they were not executed in this session.

```sh
cd fvk
kompile mini-export-text.k --backend haskell
kast --backend haskell export-text-spec.k
kprove export-text-spec.k --backend haskell
```

Expected result after a successful machine check: `#Top`.
