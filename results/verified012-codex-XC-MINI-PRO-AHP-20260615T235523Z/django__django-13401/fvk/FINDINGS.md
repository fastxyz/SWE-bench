# FVK Findings

Status: constructed, not machine-checked.

## FVK-F1: Resolved code bug, owner-insensitive field equality

Input: an abstract base `A` with `myfield`, and concrete subclasses `B(A)` and
`C(A)`.

Observed pre-fix behavior from the issue: `B._meta.get_field('myfield')` and
`C._meta.get_field('myfield')` compared equal, so a shared set retained one
entry.

Expected: the fields have different `field.model` owners and must compare
unequal; a set must retain both.

V1 status: resolved. `Field.__eq__()` now requires both equal
`creation_counter` and equal `model`. This discharges PO-EQ-OWNER and
PO-SET-CARDINALITY.

## FVK-F2: Confirmed, hash matches equality

Input: any two `Field` instances.

Observed V1 behavior by source inspection: `__hash__()` hashes
`(creation_counter, model)`.

Expected: if two fields compare equal, their hashes must be equal.

V1 status: confirmed. The hash key uses the same identity components as
equality. This discharges PO-HASH-CONSISTENCY.

## FVK-F3: Confirmed, ordering preserves creation-counter priority

Input: any two `Field` instances with different `creation_counter` values.

Observed V1 behavior by source inspection: `__lt__()` returns the counter
comparison before consulting the model sort key.

Expected: cases not affected by the equality collision must not be reordered by
model-first comparison.

V1 status: confirmed. This discharges PO-LT-PRIMARY-COUNTER.

## FVK-F4: Confirmed, same-counter ordering has an owner tie-breaker

Input: two `Field` instances with the same `creation_counter`.

Observed V1 behavior by source inspection: `__lt__()` compares
`(model._meta.label_lower, id(model))`, with unattached fields sorting before
attached fields.

Expected: `__lt__` should be adjusted to match the owner-sensitive equality
collision while preserving counter-first ordering.

V1 status: confirmed. This discharges PO-LT-COLLISION. Public intent does not
specify ordering for same-label but distinct model classes; V1's identity
component is accepted as an implementation tie-breaker only after the public
counter-first obligation.

## FVK-F5: Residual proof caveat, not machine-checked

Input: the formal claims in `fvk/field-comparison-spec.k`.

Observed in this session: K tooling was not run because the task forbids
executing K commands.

Expected: a future machine check should run the commands recorded in
`fvk/PROOF.md` and return `#Top`.

V1 status: no code change. The proof is constructed, not machine-checked.
