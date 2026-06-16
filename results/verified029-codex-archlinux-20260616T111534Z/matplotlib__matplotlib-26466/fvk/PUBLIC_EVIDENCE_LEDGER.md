# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "When an array is used as the _xy_ kwarg for an annotation that includes arrows, changing the array after calling the function changes the arrow position." | Constructor must not retain a mutable caller-owned `xy` array for later arrow endpoint computation. | Encoded by PO1 and K claims `annotation-base-xy-copy-*`. |
| E2 | `benchmark/PROBLEM.md` | "Both arrows should be horizontal." | In the reproduction, mutating `xy_0[1]` after construction must not move the first arrow from y=1 to y=3. | Encoded by PO1. |
| E3 | `benchmark/PROBLEM.md` | "using a copy of the array helps spotting where the problem is" and hint "`self.xy=np.array(xy)` is enough." | The intended operation is snapshot/copy at storage time, not live linkage to the caller array. | Encoded by all copy obligations. |
| E4 | `benchmark/PROBLEM.md` | "A similar issue is maybe present in the definition of OffsetFrom helper class." | Audit `OffsetFrom.ref_coord` for the same delayed-use aliasing pattern. | Encoded by PO2. |
| E5 | `repo/lib/matplotlib/text.py` docs | `xy : (float, float)` and `OffsetFrom.ref_coord : (float, float)`. | Coordinate inputs are two scalar coordinate values. | Domain precondition for all claims. |
| E6 | `repo/lib/matplotlib/text.pyi` | `_AnnotationBase.xy: tuple[float, float]`; `OffsetFrom.ref_coord: tuple[float, float]`. | Stored coordinates should remain tuple-like, not globally converted to arrays. | Justifies `tuple(...)` over `np.array(...)`. |
| E7 | `repo/lib/matplotlib/offsetbox.py` docs and `offsetbox.pyi` | `AnnotationBbox.xybox : (float, float), default: xy`; `xybox: tuple[float, float]`. | Explicit `xybox` and default `xybox` should be independent coordinate values. | Encoded by PO3. |
| E8 | `repo/lib/matplotlib/patches.py` docs and `patches.pyi` | `ConnectionPatch` connects point `xyA` with point `xyB`; `xy1` and `xy2` typed as tuples. | Endpoint storage may be snapshotted as tuples without signature or public type breakage. | Encoded by PO4 and compatibility audit. |
| E9 | Public tests in `repo/lib/matplotlib/tests/test_axes.py` | Existing tests compare `labels[i].xy == (x, y)`. | Avoid making tuple equality ambiguous by converting every stored coordinate to a NumPy array. | Encoded by PO5. |
