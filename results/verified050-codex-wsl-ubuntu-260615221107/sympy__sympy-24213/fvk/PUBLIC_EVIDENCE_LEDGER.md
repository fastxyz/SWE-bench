# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "collect_factor_and_dimension does not detect equivalent dimensions in addition" | Addition must use dimensional equivalence, not only raw `Dimension` equality. | Encoded by PO-1, PO-2, K claims 1-2. |
| E2 | prompt | Reproducer adds `a1*t1 + v1`; failure says `Dimension(velocity)` should match `Dimension(acceleration*time)`. | `velocity` and `acceleration*time` must be accepted as equivalent in SI. | Encoded by PO-7 and K claim 1. |
| E3 | source | `DimensionSystem.equivalent_dims` compares `get_dimensional_dependencies(dim1)` and `get_dimensional_dependencies(dim2)`. | The active dimension system is the public mechanism for deciding dimension equivalence. | Encoded by PO-2. |
| E4 | source | SI/MKS dependencies define `velocity` as `{length: 1, time: -1}` and `acceleration` as `{length: 1, time: -2}`. | `acceleration*time` reduces to `{length: 1, time: -1}` and is equivalent to `velocity`. | Encoded by PO-7. |
| E5 | public-test | Incompatible additions such as length plus time are expected to raise `ValueError`. | The fix must not make physically incompatible dimensions addable. | Encoded by PO-3 and K claim 3. |
| E6 | source | Existing accepted `Add` branch initializes from the first addend, adds each accepted factor, and returns `factor, dim`. | Return tuple shape and first-dimension return behavior are frame conditions. | Encoded by PO-4 and PO-5. |
| E7 | source | `UnitSystem.__init__` permits `dimension_system=None`. | A no-dimension-system unit system must not require equivalence machinery it does not have. | Encoded by PO-6 and K claim 4. |
