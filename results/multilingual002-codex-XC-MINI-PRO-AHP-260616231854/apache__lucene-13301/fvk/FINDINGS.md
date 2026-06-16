# FVK Findings

Status: constructed, not machine-checked.

## F1: V1 Fixed the Reported XYPoint and XYCircle Contract Bug

- Classification: confirmed repair.
- Evidence: `XYPoint.equals` now uses `Float.compare` for `x` and `y`; `XYCircle.equals`
  now uses `Float.compare` for `x`, `y`, and `radius`.
- Input shape: `new XYPoint(-0.0f, y)` vs `new XYPoint(0.0f, y)`.
- V1 behavior: equality is false, so the differing `Float.hashCode` values no longer
  violate the Java equals/hashCode contract.
- Trace: PO-1, PO-2, PO-3.

## F2: V1 Missed the Same Contract Bug in Adjacent Double-Valued Geometry Classes

- Classification: code bug found by FVK audit and fixed in V2.
- Evidence: pre-V2 `Point.equals`, `Circle.equals`, and `Rectangle2D.equals` used
  primitive `==`; their hash methods use `Double.hashCode` or `Objects.hash`, which
  preserve signed-zero differences.
- Example input: `new Point(-0.0, 1.0)` vs `new Point(0.0, 1.0)`.
- Observed before V2: `equals` could return true while hash codes differed.
- Expected: either equality must distinguish signed zero or hashing must normalize it.
  The local `Rectangle` pattern and the issue hint choose compare-based equality.
- Fix applied: changed those three `equals` methods to use `Double.compare`.
- Trace: PO-1, PO-2, PO-4, PO-5.

## F3: XYRectangle Did Not Need a Source Change

- Classification: confirmed unchanged.
- Evidence: `XYRectangle.equals` already uses `Float.compare`; `hashCode` uses
  `Float.floatToIntBits`.
- Input shape: signed-zero difference in any rectangle bound.
- Behavior: equality is false for signed-zero-distinct bounds, so unequal hashes do
  not violate the contract.
- Trace: PO-3, PO-6.

## F4: Primitive-Comparison Equality Tests Are Suspect Evidence for This Issue

- Classification: suspect public-test pattern, not a source-code obligation.
- Evidence: the issue identifies primitive floating-point `==` as the bug source.
- Consequence: a test branch that uses primitive `==`/`!=` to decide whether two
  objects should be equal is not a reliable oracle for signed zero.
- Action: no test files were modified, per task constraints.
- Trace: PO-7.

## F5: Proof Is Constructed Only

- Classification: proof/tooling limitation.
- Evidence: task forbids running tests, Python, or K tooling.
- Consequence: artifacts include commands and expected proof shape, but no claim is
  machine-checked in this session and no test-redundancy removal is recommended.
- Trace: PO-8.
