# Public Evidence Ledger

## E1: Reported Failure

- Source: `benchmark/PROBLEM.md`
- Quoted evidence: "Unexpected exception when multiplying geometry.Point and
  number"
- Semantic obligation: scalar-left multiplication of a `Point` by a number is
  in-domain and must not produce the reported exception.
- Status: encoded in `SPEC.md`, `point-scalar-spec.k`, PO1, PO2, and PO4.

## E2: Right Multiplication Works

- Source: `benchmark/PROBLEM.md`
- Quoted evidence: "This line works fine" followed by
  `point1 + point2 * sympy.sympify(2.0)`
- Semantic obligation: existing `Point * scalar` coordinate scaling is the
  reference behavior to preserve and mirror for scalar-left multiplication.
- Status: encoded in PO1, PO3, and frame condition F1.

## E3: Left Multiplication Must Match Right Multiplication

- Source: `benchmark/PROBLEM.md`
- Quoted evidence: "The expected behaviour is, that both lines give the same
  result"
- Semantic obligation: for in-domain point addition and scalar multiplication,
  `P + s * Q` must equal `P + Q * s`.
- Status: encoded in PO1 and PO4.

## E4: Public Hint Identifies Reflected Multiplication

- Source: `benchmark/PROBLEM.md`
- Quoted evidence: "You can multiply a Point on the right by a scalar but not
  on the left. I think this would be a matter of defining `__rmul__` for
  Point."
- Semantic obligation: implement the correction on `Point` reflected
  multiplication rather than changing all geometry entities or SymPy core
  multiplication.
- Status: encoded in PO2, PO6, and compatibility audit C1.

## E5: Existing Point Multiplication Semantics

- Source: `repo/sympy/geometry/point.py`
- Quoted evidence: `Point.__mul__` says "Multiply point's coordinates by a
  factor" and constructs `Point(coords, evaluate=False)`.
- Semantic obligation: the mirrored left multiplication result must use the
  same coordinate-scaling semantics.
- Status: encoded in PO1 and PO3.

## E6: SymPy Dispatch Priority Convention

- Source: `repo/sympy/core/expr.py` and `repo/sympy/core/decorators.py`
- Quoted evidence: `Expr` has `_op_priority = 10.0`, and
  `call_highest_priority('__rmul__')` calls the right operand's reflected
  method when its priority is higher.
- Semantic obligation: a SymPy scalar on the left reaches `Point.__rmul__`
  only if `Point` has priority greater than ordinary `Expr`.
- Status: encoded in PO2 and PO6.

## E7: Existing GeometryEntity Reflected Methods

- Source: `repo/sympy/geometry/entity.py`
- Quoted evidence: `GeometryEntity.__rmul__` delegates back to
  `a.__mul__(self)`, with analogous reflected add/sub/div methods.
- Semantic obligation: once `Point` receives `_op_priority`, it must override
  reflected add/sub/div as needed so priority dispatch does not recurse through
  the inherited methods.
- Status: encoded in PO5 and Finding F-002.
