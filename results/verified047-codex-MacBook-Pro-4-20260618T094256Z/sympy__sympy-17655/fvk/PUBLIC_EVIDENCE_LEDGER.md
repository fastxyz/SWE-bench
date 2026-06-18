# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | `point1 + point2 * sympy.sympify(2.0)` works. | Right-side point scaling followed by point addition is intended behavior. | Encoded in `ISSUE-EXAMPLE` claim. |
| E2 | `benchmark/PROBLEM.md` | `point1 + sympy.sympify(2.0) * point2` raises `GeometryError`. | The displayed exception is the legacy bug symptom, not behavior to preserve. | Marked SUSPECT legacy behavior; not encoded as expected. |
| E3 | `benchmark/PROBLEM.md` | "The expected behaviour is, that both lines give the same result." | Scalar-left multiplication must produce the same point value as scalar-right multiplication in the issue expression. | Encoded in `POINT-RMUL` and `ISSUE-EXAMPLE`. |
| E4 | `benchmark/PROBLEM.md` public hint | "You can multiply a Point on the right by a scalar but not on the left." | The missing reflected multiplication route should delegate to point scaling. | Encoded in `POINT-RMUL-DIRECT`. |
| E5 | `repo/sympy/geometry/point.py` docstring for `__mul__` | "Multiply point's coordinates by a factor." | Existing point multiplication is coordinate-wise scaling. | Encoded by `pointMul` semantics. |
| E6 | `repo/sympy/geometry/tests/test_point.py` | `p1.__radd__(p2)` and `__rsub__` expectations. | Direct reflected point add/sub behavior must remain compatible. | Encoded by frame claims and compatibility audit. |
| E7 | `repo/sympy/core/decorators.py` | `_op_priority` chooses the object's special method with higher priority. | A SymPy scalar only calls `Point.__rmul__` if `Point` advertises priority above `Expr`. | Encoded by `exprMul` dispatch semantics. |
| E8 | public source priority values | `Expr` is `10.0`; matrix-like priorities start above V1's `10.0001`. | Point priority should win over plain scalar `Expr` but not higher-priority non-scalar objects. | Encoded by `HIGHER-PRIORITY-FRAME`. |
