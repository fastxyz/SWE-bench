# Formal Spec in English

C-001: For the expression `polylog(2, 1/2)`, the modeled construction/evaluation step returns `pi**2/12 - log(2)**2/2`.

C-002: For any symbolic expression `z`, the modeled function expansion of `polylog(1, z)` returns `-log(1 - z)`.

C-003: The modeled `lerchphi` rational-argument polylog contributor expands a generated `polylog` subterm by applying `expand_func` to the whole expression. If that `polylog` call has already evaluated, the evaluated expression is returned safely.

Frame condition C-004: Existing automatic `polylog` cases for `z = 0`, `z = 1`, and `z = -1` remain before the new `s == 2 and z == 1/2` branch.

Frame condition C-005: Existing nonpositive integer order expansion remains in the same branch after the order-one branch.
