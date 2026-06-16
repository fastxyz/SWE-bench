# SPEC AUDIT

Status: pass, with one explicit capability boundary.

| Formal-English item | Intent item | Verdict | Notes |
| --- | --- | --- | --- |
| Zero score for `TK == 0` | Intent 2 and public zero examples | Pass | Matches docs/tests and existing zero branch. |
| Formula score for `TK > 0` | Intent 1 and 4 | Pass | Algebraic rewrite is equivalent under valid counts. |
| Avoid integer product `PK * QK` | Intent 3 and issue report | Pass | This is the central defect. |
| Valid-count assumptions | Intent 1 and pair-count definition | Pass | `TK <= PK` and `TK <= QK` follow from contingency pair counts. |
| Counts already computed correctly | Full end-to-end function behavior | Boundary | Compact K model does not prove NumPy/SciPy count construction. Recorded as F-4 and PO-7. |
| Public API compatibility | Intent 6 | Pass | No signature/import/return-shape change. |
