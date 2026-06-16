# Public Evidence Ledger

This file mirrors the evidence ledger in `fvk/SPEC.md`.

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "One of the `sin(x)` functions should be negative." | x-axis off-diagonal sine signs are opposite | encoded by PO3 |
| E2 | docstring/name | "equivalent rotation transformation matrix" | matrix must represent quaternion rotation | encoded by PO2 |
| E3 | source doc/implementation | `rotate_point` uses `q * point * conjugate(q)` and has active z-axis example | active rotation convention | encoded by PO2, PO4 |
| E4 | source implementation | `from_rotation_matrix` copies signs from matrix-entry differences | antisymmetric cross terms | encoded by PO5 |
| E5 | public tests | `Quaternion(1, 2, 3, 4)` expects legacy `M12 = 14/15` | SUSPECT legacy evidence | finding F2 |
| E6 | default-domain assumption | a quaternion "which represents rotation" | nonzero norm precondition | finding F3, PO1 |
