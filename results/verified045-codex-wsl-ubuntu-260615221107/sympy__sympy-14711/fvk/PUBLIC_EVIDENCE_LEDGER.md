# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "vector add 0 error" | Scalar zero in vector addition is the reported boundary case. | Encoded in `ADD-ZERO-RIGHT`, `PY-ADD-ZERO-LEFT`, and `SUM-REPRODUCER`. |
| E2 | prompt | `sum([N.x, (0 * N.x)])` | The concrete public reproducer must not raise and must return `N.x`. | Encoded in `SUM-REPRODUCER`. |
| E3 | prompt traceback | `TypeError: A Vector must be supplied` at `_check_vector(other)` | The error is the symptom to remove for scalar zero in addition. | Finding FVK-F1, fixed by V1. |
| E4 | prompt traceback | `#if other == 0: return self` shown next to `Vector.__add__` | Public hint that additive zero should be handled before `_check_vector`. | Supports `ADD-ZERO-RIGHT`. |
| E5 | source docstring | `The only exception is to create a zero vector: zv = Vector(0)` | `Vector(0)` is the representation of the zero vector. | Used in `MUL-ZERO-VECTOR` and `SUM-REPRODUCER`. |
| E6 | source implementation | `__radd__ = __add__` | `0 + vector` reaches the same method as `vector + other`. | Encoded in `PY-ADD-ZERO-LEFT`. |
| E7 | source implementation | `__mul__` scales components and `Vector.__init__` drops zero component matrices | `0 * vector` constructs a zero vector. | Encoded in `MUL-ZERO-VECTOR`. |
| E8 | source implementation | `_check_vector()` raises when operand is not a `Vector` | Nonzero non-vector operands should still be rejected unless public intent says otherwise. | Encoded in `NONZERO-SCALAR-REJECT`. |
| E9 | source search | `_check_vector()` is used by dot, cross, outer, frame, point, and helper APIs | Coercing scalar zero in `_check_vector()` would broaden APIs outside addition. | Finding FVK-F3; V1 intentionally avoids this. |
| E10 | default-domain | Python `sum()` starts from scalar `0` | The left scalar-zero identity is required for the reproducer. | Encoded in `SUM-REPRODUCER`. |
