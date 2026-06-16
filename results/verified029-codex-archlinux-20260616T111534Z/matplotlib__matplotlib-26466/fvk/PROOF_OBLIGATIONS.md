# Proof Obligations

Status: constructed, not machine-checked.

## PO1: `_AnnotationBase.xy` Snapshot

Precondition: `xy` is a point-like iterable containing two scalar coordinate
values `(x, y)`.

Obligation: after `_AnnotationBase.__init__` stores `xy`, any later mutation of
the caller-owned object used to supply `xy` must not change `self.xy`.

Discharged by:

- source: `self.xy = tuple(xy)` in `repo/lib/matplotlib/text.py`;
- K claims: `annotation-base-xy-copy-y` and `annotation-base-xy-copy-x`;
- proof step: mutation rewrites only the heap object; the `<annotationXY>` cell
  is framed.

## PO2: `OffsetFrom._ref_coord` Snapshot

Precondition: `ref_coord` is a two-scalar coordinate pair.

Obligation: after construction, mutations to the caller-owned coordinate object
must not change the coordinate later read by `OffsetFrom.__call__`.

Discharged by:

- source: `self._ref_coord = tuple(ref_coord)` in
  `repo/lib/matplotlib/text.py`;
- K claim: `offsetfrom-ref-copy-y`;
- symmetry: x-component mutation follows the same frame argument as PO1.

## PO3: `AnnotationBbox.xybox` Snapshot and Default

Precondition: `xy` and any explicit `xybox` are two-scalar coordinate pairs.

Obligation:

- explicit `xybox` is copied by value;
- omitted `xybox` defaults to the already copied `self.xy`, not the original
  caller-owned `xy` object.

Discharged by:

- source: `self.xybox = tuple(xybox) if xybox is not None else self.xy`;
- K claims: `annotationbbox-explicit-xybox-copy-y` and
  `annotationbbox-default-xybox-uses-copied-xy`.

## PO4: `ConnectionPatch.xy1` and `xy2` Snapshot

Precondition: `xyA` and `xyB` are two-scalar coordinate pairs.

Obligation: endpoint attributes must retain construction-time endpoint values
even if caller-owned endpoint arrays are later mutated.

Discharged by:

- source: `self.xy1 = tuple(xyA)` and `self.xy2 = tuple(xyB)`;
- K claim: `connectionpatch-endpoints-copy-y`;
- compatibility evidence: `patches.pyi` types `xy1` and `xy2` as tuples.

## PO5: Public Tuple-Like Behavior

Obligation: the fix must not break tuple indexing, unpacking, or tuple equality
used by public code/tests.

Discharged by:

- source choice: `tuple(...)` rather than `np.array(...)`;
- evidence: type stubs and public tests comparing annotation `.xy` to tuples.

## Machine-Check Commands Not Executed

The following commands are the intended machine-check path and were not run in
this environment:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/annotation-coordinate-spec.k
kprove fvk/annotation-coordinate-spec.k --definition fvk/mini-python-kompiled
```
