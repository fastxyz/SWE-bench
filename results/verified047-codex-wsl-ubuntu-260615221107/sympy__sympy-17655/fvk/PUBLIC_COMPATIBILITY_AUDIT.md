# Public Compatibility Audit

## Changed Public Symbols

### C1: `Point.__rmul__`

- Change: added reflected multiplication on `Point`.
- Public evidence: issue hint names `__rmul__` for `Point`.
- Compatibility result: compatible. It mirrors existing `Point.__mul__`; no
  public subclass overrides were found outside `Point2D` and `Point3D`, which
  inherit from `Point`.

### C2: `Point._op_priority`

- Change: added `_op_priority = 10.001`.
- Public evidence: SymPy `Expr` dispatch requires a higher right operand
  priority to call `Point.__rmul__` for `sympify(2.0) * Point`.
- Compatibility result: compatible for audited scope. The value is greater than
  ordinary `Expr` priority `10.0`, equal to or lower than matrix/poly priority
  values inspected in non-test source, and lower than vector, tensor, set,
  quaternion, units, and holonomic priority values. This limits dispatch
  capture to ordinary scalar expressions.

### C3: `Point.__radd__`, `Point.__rsub__`, `Point.__rdiv__`,
`Point.__rtruediv__`

- Change: added reflected operator shims.
- Public evidence: `GeometryEntity` inherited reflected methods delegate back
  to the left operand. After adding `_op_priority`, ordinary `Expr + Point`,
  `Expr - Point`, and `Expr / Point` would otherwise route into those inherited
  methods.
- Compatibility result: compatible. The shims preserve the symbolic
  `Expr`-left forms that `Expr` previously constructed and preserve direct
  point reflected operations by delegating non-`Expr` operands back to their
  existing methods.

## Public Callsite Scan

Non-test source callsites use point addition and right multiplication patterns,
with no public direct callsite requiring the old scalar-left `Mul(Scalar,
Point)` result. `Point2D` and `Point3D` are the only public subclasses found in
non-test source, and neither overrides the changed reflected methods.

## Compatibility Findings

No unhandled public callsite or subclass override was found for the changed
surface. The residual risk is that the proof is constructed, not
machine-checked, and the source scan is static.
