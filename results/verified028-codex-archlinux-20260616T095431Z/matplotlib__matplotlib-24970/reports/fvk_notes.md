# FVK Notes

## Decision

V1 stands unchanged. The audit found that the source edit already matches the
public-intent requirement: before assigning under, over, or bad sentinels,
integer `xa` must be able to represent `self.N + 2`.

## Trace

F-001 ties the reported empty `uint8` reproduction to PO-001, PO-002, and
PO-004. V1 satisfies those obligations by promoting `xa` when
`self._i_bad > np.iinfo(xa.dtype).max`, so no additional code change is needed
for the reported warning.

F-002 ties the broader special-index behavior to PO-001 through PO-003. This
confirms the fix is not merely suppressing a warning; it preserves the actual
bad, under, and over lookup-table indices for integer dtypes that were too
small.

F-003 rejects the modulo alternative against PO-002 and PO-003. I kept the V1
promotion approach because modulo wrapping would preserve the legacy defect by
mapping special sentinels back to ordinary colormap entries.

F-004 and PO-005 through PO-006 show that V1 is appropriately scoped: in-range
integer values are preserved, and the public method signature, float branch,
`bytes`, `alpha`, lookup, shape, and scalar-return behavior are unchanged.

F-005 and PO-007 record the proof boundary. Because this session forbids test,
Python, NumPy, and K execution, I did not run or remove tests and did not claim
machine-checked proof status.
