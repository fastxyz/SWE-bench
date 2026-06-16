# Constructed Proof

Status: constructed, not machine-checked. The K commands in
`PROOF_OBLIGATIONS.md` were written but not run.

## Claim Family

The proof covers the alias-independence claims in
`fvk/annotation-coordinate-spec.k`:

- `annotation-base-xy-copy-y`
- `annotation-base-xy-copy-x`
- `offsetfrom-ref-copy-y`
- `annotationbbox-explicit-xybox-copy-y`
- `annotationbbox-default-xybox-uses-copied-xy`
- `connectionpatch-endpoints-copy-y`

Each claim starts with a caller-owned mutable coordinate array in the heap,
stores a tuple copy in a Matplotlib object cell, then mutates the caller array.
The postcondition is that the heap reflects the mutation while the stored object
cell still contains the original coordinate pair.

## Symbolic Execution Sketch

For `_AnnotationBase.xy`, start with:

```text
<heap> arr(A) |-> pair(scalar(X), scalar(Y)) </heap>
<annotationXY> none </annotationXY>
<k> storeAnnXY(arr(A)) ~> mutate(arr(A), 1, scalar(Y2)) </k>
```

Step 1: apply `storeAnnXY`. The rule reads `X` and `Y` from the heap and writes
`tup(scalar(X), scalar(Y))` to `<annotationXY>`. The heap is unchanged.

Step 2: apply `mutate` for index 1. The heap rewrites to
`arr(A) |-> pair(scalar(X), scalar(Y2))`. No rule mentions
`<annotationXY>`, so by framing that cell remains
`tup(scalar(X), scalar(Y))`.

By transitivity, the full sequence reaches the claimed post-state. The x
component claim is identical except that `mutate` rewrites the first component.

## Other Storage Sites

`OffsetFrom._ref_coord` and explicit `AnnotationBbox.xybox` use the same
two-step proof:

1. the storage command copies heap values into a distinct stored tuple cell;
2. later mutation rewrites only the heap, so the stored tuple is framed.

For omitted `AnnotationBbox.xybox`, symbolic execution has one additional step:

1. `storeAnnXY(arr(A))` writes copied `xy` to `<annotationXY>`;
2. `defaultXYBox` copies `<annotationXY>` into `<xybox>`;
3. later mutation rewrites only the heap, leaving both stored cells framed.

For `ConnectionPatch`, `storeConnection(arr(A), arr(B))` writes independent
tuples to `<xy1>` and `<xy2>`. Later mutations rewrite only the two heap
objects. Both endpoint cells are framed.

## Adequacy Check

`FORMAL_SPEC_ENGLISH.md` paraphrases each claim, and `SPEC_AUDIT.md` compares
those paraphrases to `INTENT_SPEC.md`. All claim paraphrases pass for the
coordinate-storage contract. The formal claims do not assert broader rendering
properties, and those are explicitly out of scope.

## Test Guidance

The constructed proof subsumes point tests that only check constructor-time
alias independence for in-domain scalar coordinate arrays, once the K claims are
machine-checked. No tests should be removed now because the proof has not been
machine-checked and the benchmark forbids test edits.

Suggested tests to keep or add in a normal development environment:

- `Annotation` with NumPy `xy`, arrowprops, and post-construction mutation;
- `OffsetFrom` with NumPy `ref_coord` and post-construction mutation;
- `AnnotationBbox` with omitted and explicit NumPy `xybox`;
- `ConnectionPatch` endpoint arrays if maintainers accept that broader
  consistency coverage.

## Residual Risk

- Partial correctness only: the proof shows the storage frame property if the
  modeled commands execute.
- Trusted base: adequacy of the mini-Python abstraction, the K reachability
  proof system, and a future `kprove` run.
- Out-of-domain inputs with mutable coordinate elements are not covered.
