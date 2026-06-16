# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests,
or project code were executed.

## Claims

The formal claims are encoded in `fvk/string-value-facet-counts-spec.k` over the
abstract semantics in `fvk/mini-java-facet.k`.

The core claims are:

- `TOP-EMPTY`: no count storage plus valid `getTopChildren` input reaches an empty
  facet result with child count `0`.
- `ALL-EMPTY`: no count storage plus valid `getAllChildren` input reaches the same
  empty facet result.
- `SPECIFIC-PRESENT-EMPTY`: no count storage plus an existing term reaches count
  `0`.
- `SPECIFIC-ABSENT`: an absent term reaches count `-1`.
- `TOP-DENSE-FRAME` and `TOP-SPARSE-FRAME`: non-empty storage remains on the
  pre-existing count path.

## Proof Sketch

### PO-001

`hasCountStorage()` is defined as `sparseCounts != null || denseCounts != null`.
Boolean negation gives the exact empty state:
`sparseCounts == null && denseCounts == null`.

### PO-002

In `getTopChildren`, Java executes:

1. `validateTopN(topN)`.
2. `validateDimAndPathForGetChildren(dim, path)`.
3. `if (hasCountStorage() == false) return emptyResult();`.

Under the PO-002 preconditions, steps 1 and 2 pass. By PO-001, step 3 is true.
`emptyResult()` asserts `totalDocCount == 0` and constructs
`FacetResult(field, new String[0], totalDocCount, new LabelAndValue[0], 0)`.
No later dense branch is reachable, so `denseCounts.length` is not evaluated.

### PO-003

`getAllChildren` validates the field and path, then checks the same
`hasCountStorage() == false` condition before building the label list. Under PO-003
the method returns `emptyResult()` and never enters the dense loop over
`denseCounts.length`.

### PO-004

The source order places validation before the empty-storage guard in
`getTopChildren`. Therefore the proof of PO-002 applies only to valid inputs.
Invalid `topN`, dimension, or path shape remains governed by the pre-existing
validation methods.

### PO-005

`getSpecificValue` validates `dim` and `path.length`, then computes `ord` using
`docValues.lookupTerm`. If `ord >= 0` and no count storage exists, the new guard
returns `0`. Since the return happens before the final ternary expression, the
method does not dereference `denseCounts[ord]`.

### PO-006

If `ord < 0`, `getSpecificValue` returns `-1` before the empty-storage guard.
This preserves the `Facets` contract for paths that do not exist.

### PO-007

If either count store exists, `hasCountStorage()` is true, so the new empty guards
do not fire. Control flows to the same sparse/dense loops or count lookup used by
the pre-V1 implementation.

### PO-008

`getAllDims(topN)` validates `topN` and returns
`Collections.singletonList(getTopChildren(topN, field))`. Under empty storage,
the delegated `getTopChildren` call satisfies PO-002.

### PO-009

The diff adds only private helpers and method bodies. Public signatures and
override declarations are unchanged. Public compatibility therefore follows by
syntactic frame: callers and subclasses observe the same API surface.

## Machine-Check Commands

These commands are emitted for later machine checking and were not run:

```sh
(cd fvk && kompile mini-java-facet.k --backend haskell)
(cd fvk && kast --backend haskell string-value-facet-counts-spec.k)
(cd fvk && kprove string-value-facet-counts-spec.k)
```

Expected outcome after a successful machine check:

```text
#Top
```

## Test Guidance

Because the proof is not machine-checked, no tests should be removed. A targeted
test for the reported case remains useful until `kprove` returns `#Top`.

Suggested public-style checks, not executed here:

- `getTopChildren(10, "field")` after `MatchNoDocsQuery` returns `childCount == 0`.
- `getAllChildren("field")` after no hits returns no labels and child count `0`.
- `getSpecificValue("field", "foo")` after no hits returns `0` when `foo` exists.
- `getSpecificValue("field", "missing")` returns `-1`.

## Residual Risk

This is a partial correctness proof over a minimal model. It does not prove
termination or Lucene priority-queue ordering. Those properties are unchanged by
V1 and outside the null-storage failure under audit.
