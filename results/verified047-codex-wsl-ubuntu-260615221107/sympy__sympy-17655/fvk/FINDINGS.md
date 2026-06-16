# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and proof-obligation construction only.

## F-001: Pre-V1 scalar-left multiplication produced a symbolic `Mul`

- Classification: code bug, resolved by V1.
- Evidence: `benchmark/PROBLEM.md` reports
  `point1 + sympify(2.0) * point2` raising `GeometryError`.
- Input: `Point(0, 0) + sympify(2.0) * Point(1, 1)`.
- Observed before V1: `sympify(2.0) * Point(1, 1)` became a symbolic
  `Mul(2.0, Point2D(1, 1))`; then `Point.__add__` attempted to convert that
  `Mul` into a `Point` and failed.
- Expected: same result as `Point(0, 0) + Point(1, 1) * sympify(2.0)`.
- V1 status: resolved by `Point._op_priority = 10.001` plus
  `Point.__rmul__` delegating to `Point.__mul__`.
- Proof obligations: PO1, PO2, PO3, PO4.

## F-002: Adding `_op_priority` without reflected shims would introduce recursion

- Classification: compatibility bug avoided by V1.
- Evidence: `GeometryEntity.__radd__`, `__rsub__`, `__rdiv__`, and `__rmul__`
  delegate back to the left operand.
- Input family: ordinary SymPy expression on the left and `Point` on the right,
  such as `x + Point(1, 2)`, `x - Point(1, 2)`, or `x / Point(1, 2)`.
- Observed risk without shims: once `Point` has priority greater than `Expr`,
  `Expr.__add__`/`__sub__`/`__div__` would call inherited `GeometryEntity`
  reflected methods, which delegate back to the same left `Expr` operation.
- Expected: preserve the symbolic expression forms previously constructed by
  `Expr`.
- V1 status: resolved by `Point.__radd__`, `Point.__rsub__`, and
  `Point.__rdiv__` shims; `__rtruediv__` aliases `__rdiv__`.
- Proof obligations: PO5, PO7.

## F-003: Priority value must be narrow enough not to capture higher-priority systems

- Classification: compatibility condition, satisfied by V1 static audit.
- Evidence: `Expr._op_priority` is `10.0`; non-test source shows matrices at
  `10.001`/`10.01`, vectors at `12+`, and several domain-specific systems at
  `11+`.
- Input family: `OtherSystem * Point`, where `OtherSystem` has its own
  priority and arithmetic protocol.
- Expected: ordinary scalar expressions dispatch to `Point.__rmul__`; known
  higher-priority systems keep their own precedence.
- V1 status: satisfied by `_op_priority = 10.001`, which is greater than
  ordinary `Expr` and not greater than the inspected matrix/vector priorities.
- Proof obligations: PO6, PO7.

## Open Findings

None requiring a source change were found. Residual risk is limited to the FVK
honesty gate: the proof is constructed, not machine-checked, and no tests or
runtime checks were run by instruction.

## Test Guidance

Do not modify tests in this benchmark. If tests were being added in a normal
development flow, add cases for:

- `sympify(2.0) * Point(1, 1) == Point(1, 1) * sympify(2.0)`
- `Point(0, 0) + sympify(2.0) * Point(1, 1)` matching the right-multiply form
- Python numeric left multiplication, such as `2 * Point(1, 1)`
- symbolic scalar left multiplication, such as `x * Point(1, 2)`
- `Expr + Point`, `Expr - Point`, and `Expr / Point` compatibility frames
