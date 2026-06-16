# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Formal claim | Result |
| --- | --- | --- | --- | --- |
| PO1 | Right scalar-zero identity: `vector + 0 == vector`. | E1, E4 | `ADD-ZERO-RIGHT` | Discharged by V1's early scalar-zero branch. |
| PO2 | Left scalar-zero identity through reflected addition: `0 + vector == vector`. | E2, E6, E10 | `PY-ADD-ZERO-LEFT` | Discharged because `__radd__ = __add__` and V1 handles scalar zero. |
| PO3 | Existing vector-plus-vector addition is preserved. | E8 and compatibility frame condition | `VECTOR-VECTOR-ADD` | Discharged because V1 only intercepts non-`Vector` zero. |
| PO4 | Public reproducer: `sum([vector, 0 * vector]) == vector`. | E2, E5, E7, E10 | `MUL-ZERO-VECTOR`, `SUM-REPRODUCER` | Discharged by combining zero multiplication, reflected addition, and vector-plus-zero identity. |
| PO5 | Nonzero non-vector operands still raise `TypeError`. | E8 | `NONZERO-SCALAR-REJECT` | Discharged because V1 falls through to unchanged `_check_vector()`. |
| PO6 | Shared `_check_vector()` consumers are not broadened. | E9 | Compatibility audit | Discharged because `_check_vector()` was not edited. |
| PO7 | Public API compatibility: no signature or return-shape change beyond scalar-zero addition. | Source inspection | Compatibility audit | Discharged; only `Vector.__add__` body changed. |
| PO8 | Machine-check commands are emitted and labeled correctly. | FVK verify instructions | `PROOF.md` command section | Discharged as constructed-only; not machine-checked in this session. |

No proof obligation requires a source change beyond V1.
