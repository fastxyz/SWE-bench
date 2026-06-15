# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Provenance | Disposition |
| --- | --- | --- | --- |
| PO-001 | `Q` VLA columns must dispatch to the row-wise VLA comparison path. | E-003, E-004 | Discharged by `col.format.format in ("P", "Q")`. |
| PO-002 | Existing `P` VLA columns must continue to dispatch to the row-wise VLA comparison path. | E-004, frame condition | Discharged by the same `("P", "Q")` membership check. |
| PO-003 | VLA row length/shape is part of row content equality; different shapes must be reported different. | E-001, E-002, VLA semantics | Discharged by `_vla_values_differ` shape check before value comparison. |
| PO-004 | Floating VLA rows must follow FITSDiff's invalid-floating-value policy. | E-006, E-007 | Discharged by routing floating rows through `where_not_allclose`. |
| PO-005 | Non-floating numeric VLA rows preserve the previous tolerance-aware numeric comparison. | V1 implementation, frame condition | Discharged by retaining `np.allclose` for non-floating numeric arrays. |
| PO-006 | Non-numeric VLA rows use exact element equality after shape equality. | Default table diff semantics, frame condition | Discharged by `bool(np.any(a != b))`. |
| PO-007 | Non-VLA column dispatch must be unchanged. | E-005, frame condition | Discharged because the VLA helper is called only in the `P`/`Q` branch. |
| PO-008 | The top-level format-code check must be defined for columns reaching `TableDataDiff._diff`. | E-005 | Discharged by `Column._verify_keywords` and `_ColumnFormat.__new__`, which normalize `Column.format`. |
| PO-009 | If no VLA row differs, `diff_total` and `diff_values` receive no VLA row contribution. | `TableDataDiff._diff` aggregation code | Discharged by empty `diffs[0]`; aggregation uses `len(set(diffs[0]))` and iterates over `diffs[0]`. |
| PO-010 | If at least one VLA row differs, each differing row index is made available to the existing aggregation/reporting code. | `TableDataDiff._diff` aggregation code | Discharged by the row-index list comprehension over `_vla_values_differ`. |
