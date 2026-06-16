# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "`len` of rank-0 arrays returns 0" | Current `len` result for rank-0 arrays is the reported defect. | Encoded as a negative finding. |
| E2 | prompt | "correct value should be one" | Rank-0 scalar arrays have exactly one element for length purposes. | Encoded in scalar claims C1-C4. |
| E3 | prompt | "which is the number of elements of the iterator" and `len(list(a)) == 1` | `len` should count scalar array elements and agree with the scalar iterator example. | Encoded in scalar claims C1-C4. |
| E4 | prompt | `numpy.asarray(1).size` is `1` | External scalar-array size convention supports size one for rank-0 arrays. | Encoded in scalar claims C1-C4. |
| E5 | docstring/name | `NDimArray.__len__`: "Returns number of elements in array." | Length is a total element count, not the rank or the first dimension. | Encoded in all claims. |
| E6 | public test | `assert len(array_with_long_shape) == 3 * 3` | Nonempty shapes keep product-of-dimensions length. | Encoded in claim C5. |
| E7 | public test, suspect | `assert len(rank_zero_array) == 0` | This conflicts with E1-E4 because it asserts the behavior the issue reports as the bug. | Marked SUSPECT; not used as an expected behavior. |
| E8 | implementation | `NDimArray.__len__` returns `self._loop_size`. | Constructors must cache the intended element count in `_loop_size`; changing only prose or a wrapper is insufficient. | Encoded in proof obligations PO1-PO3. |
| E9 | implementation | Dense and sparse mutable/immutable constructors each compute `_loop_size`. | The fix must cover all four constructor paths to keep `NDimArray.__len__` consistent across storage and mutability variants. | Encoded in scalar claims C1-C4. |
