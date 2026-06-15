# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Existing `OuterRef` Survives One Extra Generated Query Level

- Intent: I1, I2; evidence E1, E2, E3, E4.
- Formal claim: `OUTERREF-SHIFT`.
- Obligation: `pipeline(OuterRef(FRef("pk")), 0, 1, 2)` must reduce to `Bound(2, "pk")`.
- Status: discharged by symbolic reduction in `PROOF.md`.

## PO2: V0 Binds to the Wrong Immediate Parent Level

- Intent: bug witness for I1; evidence E3.
- Formal claim: `V0-COUNTEREXAMPLE`.
- Obligation: `pipelineV0(OuterRef(FRef("pk")), 0, 1, 2)` reduces to `Bound(1, "pk")`, matching the public wrong-alias diagnosis.
- Status: discharged as a counterexample to the old behavior.

## PO3: Plain `F()` Compatibility Is Preserved

- Intent: I3; evidence E5.
- Formal claim: `PLAIN-F-PRESERVED`.
- Obligation: `pipeline(FRef("local_field"), 0, 1, 2)` must reduce to `Bound(1, "local_field")`.
- Status: discharged by symbolic reduction; V1 leaves the existing `elif isinstance(filter_rhs, F)` branch intact.

## PO4: Non-Expression RHS Values Are Preserved

- Intent: I4.
- Formal claim: `NON-EXPRESSION-PRESERVED`.
- Obligation: `pipeline(Literal("rhs"), 0, 1, 2)` must reduce to `Literal("rhs")`.
- Status: discharged by symbolic reduction.

## PO5: Public Compatibility Is Preserved

- Intent: I5; evidence E7.
- Formal artifact: `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Obligation: no method signature, return shape, public call protocol, or non-targeted RHS handling changes.
- Status: discharged by source inspection.

## PO6: Full SQL Generation Remains Out Of Scope

- Intent: honesty gate.
- Formal artifact: `SPEC.md`, `PROOF.md`.
- Obligation: clearly label that the proof verifies reference-scope preservation, not complete SQL generation or database execution.
- Status: recorded as residual risk and an escalation boundary, not a code defect.

