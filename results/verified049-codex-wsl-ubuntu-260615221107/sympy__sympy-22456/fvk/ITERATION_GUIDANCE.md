# Iteration Guidance

Status: V1 stands unchanged.

## Source decision

No V2 source edits are recommended. Findings F1-F3 are already resolved by V1,
and the proof obligations PO1-PO6 are discharged by static source inspection.

## Recommended follow-up tests

Do not modify tests in this task. For a normal development branch, add or update
public tests for:

- `String("x").func(*String("x").args) == String("x")`
- `QuotedString("x").func(*QuotedString("x").args) == QuotedString("x")`
- `Comment("x").func(*Comment("x").args) == Comment("x")`
- `all(isinstance(arg, Basic) for arg in String("x").args)`
- default `atoms()` on codegen token trees still returning `String` leaves

## Machine-check follow-up

When an execution environment exists, run the commands emitted in
`fvk/PROOF.md`, then run the relevant SymPy tests. Until then the proof remains
constructed, not machine-checked.

## Open questions

No user clarification is needed for this issue. The public intent fixes the
placement of the change on the constructor/reconstruction path rather than a
printer or kwargs-only path.
