# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or test commands were executed.

## Claims Proved in the Model

The K claims in `hexbin-mincnt-spec.k` prove the selected-bin predicate for a
finite list of non-negative bin counts:

- `CLAIM-LOOP`: `loop(TH, counts, out)` appends one Boolean per count, where the
  Boolean is `count >= TH`.
- `CLAIM-COUNT-EXPLICIT`: count-only explicit positive `mincnt=M` uses
  threshold `M`.
- `CLAIM-C-EXPLICIT`: `C` mode explicit positive `mincnt=M` uses threshold `M`.
- `CLAIM-C-DEFAULT`: `C` mode omitted `mincnt` uses threshold `1`.
- `CLAIM-COUNT-DEFAULT`: count-only omitted `mincnt` uses threshold `0`.

## Source-Level Cardinality Lemma

Before `Axes.hexbin` branches on `C is None`, it computes `i1`, `i2`, and
`bdist`. In the count-only path, `np.bincount` counts those exact assignments.
In the `C` path, the loop over `range(len(x))` appends `C[i]` to the same
selected bin. Both paths drop index `0`, the out-of-range sentinel.

Inductively over the point index, every in-range point increments exactly the
same real bin cardinality in both paths. Thus `len(acc)` in the `C` path is the
same per-bin count used by the count-only path.

## Loop Proof

Claim: for any finite count list `COUNTS`, non-negative threshold `TH`, and
output prefix `OUT`, executing `loop(TH, COUNTS, OUT)` reaches
`OUT keepAtLeast(COUNTS, TH)`.

Proof by guarded circularity on the list structure:

1. Base case: `COUNTS == .List`. The semantics rewrites
   `loop(TH, .List, OUT)` to `OUT`. The spec function
   `keepAtLeast(.List, TH)` is `.List`, so the post-state is `OUT`.
2. Step case: `COUNTS == ListItem(N) REST`. The semantics rewrites one real
   step to `loop(TH, REST, OUT ListItem(N >=Int TH))`. Guardedness is satisfied
   by that rewrite. The circularity hypothesis applies to `REST`, yielding
   `OUT ListItem(N >=Int TH) keepAtLeast(REST, TH)`, which is exactly
   `OUT keepAtLeast(ListItem(N) REST, TH)` by the spec-function definition.
3. Verification conditions are linear integer facts: `N >= 0`, `TH >= 0`, and
   list structural consumption. No nonlinear arithmetic lemma is needed.

## Function-Contract Proofs

Each mode-specific claim first rewrites `select(mode, mincnt, counts)` to a
`loop` with the mode's effective threshold:

- `threshold(countMode, some(M)) => M`
- `threshold(cMode, some(M)) => M`
- `threshold(cMode, none) => 1`
- `threshold(countMode, none) => 0`

The loop claim then gives the corresponding `keepAtLeast` result. For explicit
positive `M`, count mode and `C` mode have the same threshold and therefore the
same selected-bin predicate for every bin count. In particular, when `M == 1`, a
bin with count one is selected in both modes.

## Adequacy and Coverage

The proof covers the min-count selected-bin predicate. It does not prove
coordinate assignment geometry, `PolyCollection` rendering, color normalization,
or marginal bar behavior. Those are frame conditions because V1 did not change
them, and public intent for this issue is the threshold inconsistency.

The proof is partial correctness. It assumes finite inputs and does not claim a
machine-checked total-correctness result.

## Commands to Machine-Check Later

These commands are required by the FVK method but were not executed in this
session:

```sh
cd fvk
kompile mini-hexbin.k --backend haskell
kast --backend haskell hexbin-mincnt-spec.k
kprove hexbin-mincnt-spec.k
```

Expected result after adapting to the local K installation, if any syntax
adjustment is needed: `kprove` returns `#Top` for all claims.

## Test Redundancy Recommendation

No existing public test in `repo/lib/matplotlib/tests/test_axes.py` asserts the
`mincnt` behavior from this issue, so no test is recommended for removal.
Existing rendering, empty-input, log-scale, and clim tests should be kept.

Recommended future tests, not added here because test files are fixed by the
task:

- `C=None`, `mincnt=1`: bins with exactly one point are displayed.
- `C` supplied, `mincnt=1`, reducer `np.sum`: the same bins are displayed as
  the count-only case.
- `C` supplied, `mincnt=None`: empty bins are not reduced/displayed.
