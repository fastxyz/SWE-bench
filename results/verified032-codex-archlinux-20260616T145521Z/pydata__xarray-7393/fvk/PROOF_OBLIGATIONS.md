# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Intent adequacy

Statement: The formal contract must express dtype preservation for stacked
MultiIndex level coordinates, not merely the current implementation behavior.

Evidence: `PUBLIC_EVIDENCE_LEDGER.md` E1, E2, E3.

Status: discharged by `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and
`SPEC_AUDIT.md`.

## PO2: Metadata propagation

Statement: The original coordinate dtype must reach the adapter before
`__array__` runs.

Evidence: `PUBLIC_EVIDENCE_LEDGER.md` E4 and E5.

Status: discharged by source inspection. No source change beyond V1 is needed.

## PO3: Default effective dtype

Statement: If `dtype is None`, `PandasMultiIndexingAdapter.__array__` must use
`self.dtype` as the effective dtype.

Evidence: public intent E3 and base adapter convention E6.

Status: discharged by V1 and formal claim `MI-ARRAY-DEFAULT-LEVEL-DTYPE`.

## PO4: Level branch materialization

Statement: For `level is not None`, the returned ndarray must be produced by
casting the pandas level values to the effective dtype.

Evidence: public intent E1, E2, E3.

Status: discharged by V1 and formal claims `MI-ARRAY-DEFAULT-LEVEL-DTYPE` and
`STACKED-LEVEL-VALUES-DTYPE`.

## PO5: Explicit dtype override

Statement: If a dtype is explicitly supplied to `__array__`, the result uses
that dtype rather than `self.dtype`.

Evidence: NumPy `__array__` protocol convention, mirrored by the existing base
adapter behavior.

Status: discharged by V1 and formal claim `MI-ARRAY-EXPLICIT-DTYPE`.

## PO6: Value preservation under cast

Statement: Within the castable domain, the result contains the pandas level
values converted to the effective dtype; the fix must not reorder, drop, or
invent coordinate values.

Evidence: public issue concerns dtype, not value changes; V1 calls
`np.asarray` on the same pandas level values.

Status: discharged by the formal model's `castValues` postcondition, subject to
the NumPy cast trusted boundary in F5.

## PO7: Non-level branch compatibility

Statement: For `level is None`, the method continues to delegate to
`PandasIndexingAdapter.__array__`.

Evidence: public compatibility audit and base adapter convention E6.

Status: discharged by V1 and formal claim `MI-ARRAY-NONLEVEL-DELEGATES`.

## PO8: Public API compatibility

Statement: The method signature, return type, and producer/consumer metadata
shape must remain compatible.

Evidence: `PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged; no unhandled public callsite or override found.

## PO9: Honesty gate

Statement: Because execution is forbidden, the FVK proof and commands are
constructed, not machine-checked, and no tests may be removed.

Evidence: task instructions and FVK docs.

Status: discharged by labeling all proof artifacts and by leaving tests
untouched.

