# PROOF_OBLIGATIONS

Status: constructed, not machine-checked.

## PO-001: Reported real-integer construction passes

Source: E-001.

For a coordinate list containing real numeric coordinates, including the prompt
case `Integer(1), Integer(2)`, validation under ambient `evaluate(False)` must
reach `ok` rather than `imaginaryError`.

Formal claim coverage: `POINT-VALIDATE-PASS`.

Status: discharged in the constructed proof by forcing the validation sub-run
to use evaluated semantics.

## PO-002: Evaluation-context invariance for real numeric coordinates

Source: E-002 and F-001.

For every finite coordinate list `CS` with no evaluated nonzero imaginary
coordinate, the validation outcome is `ok` for both old ambient flags
`OLD == true` and `OLD == false`. This includes `residualZeroNum`, which models
real numeric expressions that need helper evaluation inside `im.eval` to reduce
their imaginary part to zero.

Formal claim coverage: `POINT-VALIDATEEVAL-PASS`,
`POINT-VALIDATE-PASS`.

Status: discharged in the constructed proof for the mini-K abstraction.

## PO-003: Numeric non-real coordinates still raise

Source: E-003 and F-003.

For every finite coordinate list `CS` with any coordinate whose evaluated
imaginary part is nonzero, validation reaches `imaginaryError`.

Formal claim coverage: `POINT-VALIDATEEVAL-ERROR`,
`POINT-VALIDATE-ERROR`.

Status: discharged in the constructed proof for the mini-K abstraction.

## PO-004: Non-numeric symbolic coordinates are not rejected by this guard

Source: E-004 and F-004.

If `a.is_number` is not true, this guard must not call the coordinate imaginary
part a numeric imaginary coordinate, even if the expression may be complex.

Formal claim coverage: `POINT-SYMBOLIC-FRAME`.

Status: discharged by the retained `a.is_number and ...` guard shape.

## PO-005: Ambient evaluation flag is restored

Source: E-005 and F-001.

For any old ambient evaluation flag `OLD`, after validation exits with either
`ok` or `imaginaryError`, `global_parameters.evaluate` is restored to `OLD`.

Formal claim coverage: all `POINT-VALIDATE*` claims carry `<eval> OLD => OLD`.

Status: discharged by the constructed proof and by use of the existing
`evaluate` context manager.

## PO-006: No public API or parser compatibility regression

Source: F-002, F-003, F-004.

The repair must not change public constructor signatures, parser behavior, test
files, or the point-level `evaluate` option for float rationalization.

Formal claim coverage: compatibility is audited in
`PUBLIC_COMPATIBILITY_AUDIT.md`; no K claim needed because no public interface
shape changes.

Status: satisfied by source diff inspection.

## PO-007: Honesty gate

Source: F-005.

All proof and test-redundancy statements must be labeled "constructed, not
machine-checked"; commands are emitted for later checking, but not executed.

Formal claim coverage: `PROOF.md` reproduction commands.

Status: satisfied.
