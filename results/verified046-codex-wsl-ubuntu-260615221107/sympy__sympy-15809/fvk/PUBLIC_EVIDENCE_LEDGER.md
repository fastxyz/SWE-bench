# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt/issue | "Zero-argument Min() and Max()" | Empty argument list is in domain for both public constructors. | Encoded in claims `MIN-EMPTY` and `MAX-EMPTY`. |
| E2 | prompt/issue | "Right now `Min()` and `Max()` with no arguments raise `ValueError...`" | The previous exception is the reported defect, not intended behavior. | Recorded as Finding F1. |
| E3 | prompt/issue | "have them return `oo` and `-oo`, respectively" | `Min()` returns `oo`; `Max()` returns `-oo`. | Encoded in claims `MIN-EMPTY` and `MAX-EMPTY`. |
| E4 | prompt/issue | "valid answers mathematically" for extended real empty sets | Use lattice/extended-real identity semantics for the empty set. | Encoded as identity lookup in `mini-python.k`. |
| E5 | source/docstring | `Max.identity = S.NegativeInfinity`; `Min.identity = S.Infinity` | Existing subclass identity fields already hold the intended results. | Used by the implementation and by proof obligation PO1/PO2. |
| E6 | source/API contract | `LatticeOp` documents an identity element and its constructor returns identity when filtered arguments are empty. | Returning an identity for an empty lattice operation is a local SymPy convention. | Supports V1 placement in `MinMaxBase.__new__`. |
| E7 | public tests | `raises(ValueError, lambda: Min())` and `raises(ValueError, lambda: Max())` | These tests preserve the issue's reported bug. | Marked SUSPECT; not used to block the fix. |
| E8 | source flow | After the zero-argument branch, V1 leaves the non-empty filtering/collapse/local-zero logic unchanged. | Non-empty calls retain existing behavior modulo the normal constructor path. | Encoded in claim `NONEMPTY-FRAME`. |

