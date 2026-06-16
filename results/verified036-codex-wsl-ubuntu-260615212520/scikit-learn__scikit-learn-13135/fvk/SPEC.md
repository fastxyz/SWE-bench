# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK run audits the V1 fix for
`KBinsDiscretizer(strategy='kmeans')` in
`repo/sklearn/preprocessing/_discretization.py`. The audited behavior is the
reported failure mode: KMeans returns centers in an order that is not guaranteed
to be sorted by feature value, midpoint edges are then learned in that arbitrary
order, and `transform` can raise because `np.digitize` requires monotonic bins.

The spec is partial correctness over the supported path: finite numeric 2D
input accepted by existing validation, valid `n_bins`, nonconstant features,
and successful KMeans fitting that returns one center per requested bin.

## Public intent ledger

The standalone ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical obligations:

- E-001/E-002: unordered centers and edges are the bug mechanism; digitize is
  the consumer that requires monotonic bins.
- E-003: the reproducer with `n_bins=5` should complete without this error.
- E-004: one-dimensional k-means discretization defines intervals by nearest
  centers, so center adjacency means numeric adjacency.
- E-007: the repair must not alter public API or unrelated strategies.

## Formal model

The supporting K-style artifacts are:

- `mini-python.k`: a minimal ordered-list and midpoint-edge fragment modeling
  the property under audit.
- `kbins-discretizer-spec.k`: reachability claims for sorting centers, building
  monotonic edges, and passing a monotonic edge suffix to digitization.

The model abstracts Python/NumPy floating values to an ordered scalar domain.
This preserves the pass/fail property being verified: whether learned edges are
nondecreasing. It intentionally does not model the full NumPy or KMeans
implementation.

## Contract

For every nonconstant feature in the audited domain:

1. Let KMeans return one-dimensional centers `c0, ..., c{k-1}`.
2. Sort those centers into nondecreasing value order.
3. Build edges as:
   `[col_min, (c0+c1)/2, (c1+c2)/2, ..., (c{k-2}+c{k-1})/2, col_max]`.
4. The resulting edge list is nondecreasing.
5. The suffix `bin_edges_[1:]` consumed by `transform` is nondecreasing.
6. Therefore the reported `np.digitize` monotonicity failure is removed.

## Frame conditions

The fix must preserve:

- public class and method signatures;
- learned attribute names and shapes;
- `uniform`, `quantile`, constant-feature, validation, and encoding behavior;
- the use of KMeans centers as the basis for k-means bins, with only their
  order changed to the required one-dimensional interval order.

## Adequacy conclusion

The formal English paraphrase in `FORMAL_SPEC_ENGLISH.md` matches the intent
items in `INTENT_SPEC.md`; `SPEC_AUDIT.md` marks all audited obligations as
pass. No adequacy failure blocks keeping V1.
