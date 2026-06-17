# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Dimensionless function normalization

Claim: If `_collect_factor_and_dimension(arg)` returns `(F, D)` and
`_is_dimensionless(D)` returns true, then collecting `func(arg)` returns a result
whose dimension component is `Dimension(1)`.

Public intent: I1, I2, I3.

Discharged by: `unitsystem-collect-spec.k` claim
`FUNCTION-DIMENSIONLESS-RC` and proof section P2.

## PO2: Reported additive expression succeeds

Claim: Under the SI dependency facts for time, capacitance, and impedance,
collecting `100 + exp(second/(ohm*farad))` does not raise a dimension mismatch
and yields a dimension equivalent to `Dimension(1)`.

Public intent: I2, I3, I4.

Discharged by: `unitsystem-collect-spec.k` claim `ADD-REPORTED-EXPR` and proof
section P3.

## PO3: Incompatible additions still raise

Claim: If addend dimensions are neither structurally equal nor dimension-system
equivalent, `_collect_factor_and_dimension()` raises `ValueError` from the `Add`
branch.

Public intent: I5, I6.

Discharged by: `unitsystem-collect-spec.k` claim `ADD-INCOMPATIBLE-DIMS` and
proof section P4.

## PO4: Conservative behavior for unsupported dimension-system checks

Claim: If `DimensionSystem.is_dimensionless()` or `equivalent_dims()` cannot
analyze a dimension expression and raises `TypeError`, the V2 helpers return
false for the new normalization/equivalence checks.

Public intent: I5, I9.

Discharged by: `unitsystem-collect-spec.k` claims `FUNCTION-UNSUPPORTED-DIM`
and `ADD-UNSUPPORTED-DIM`, plus proof section P5.

## PO5: Public compatibility and frame conditions

Claim: The patch preserves method signatures, keeps non-strict function
collection for dimensionful arguments, keeps scale-factor collection unchanged,
and still rejects dimension-incompatible additions.

Public intent: I5, I6, I7.

Discharged by: source diff inspection and proof section P6.

## PO6: Machine-check command reproducibility

Claim: The FVK packet records exact K commands needed to machine-check the
constructed proof later, without executing them in this environment.

Public intent: FVK no-exec constraint.

Discharged by: `PROOF.md` section "Machine-check commands".
