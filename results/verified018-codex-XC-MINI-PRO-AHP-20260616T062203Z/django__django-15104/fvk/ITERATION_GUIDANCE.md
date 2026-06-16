# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The audit found one real source defect, F-001, and V1 directly discharges it through PO-001 and PO-003. The remaining obligations confirm that the edit preserves intended behavior for relation fields with `"to"`, non-relation fields, loop ordering/cardinality, and public compatibility.

## Why No Additional Source Change Is Justified

Changing the condition to `if field.remote_field and field.remote_field.model and 'to' in deconstruction[2]` would also avoid the exception, but it would encode the missing-key case by skipping the body rather than by making the removal operation total. PO-001 and PO-003 are already discharged by `pop('to', None)`, and no public intent requires a different shape.

Changing adjacent `generate_renamed_fields()` code is not justified. F-004 shows the nearby direct access to `old_field_dec[2]['to']` is already guarded by membership.

Adding broader validation for malformed `deconstruct()` return shapes is not justified. F-005 and PO-007 classify non-dict kwargs as outside Django's documented field deconstruction contract and unrelated to the reported issue.

## Recommended Next Tests Outside This Session

Do not modify tests in this task. In a normal Django development environment, add coverage for:

1. A custom relation field that hardcodes `to` and removes `"to"` from `deconstruct()`.
2. A normal relation field that still includes `"to"` in deconstruction.
3. A non-relation field to confirm the helper only strips relation targets.

## Residual Risk

The proof is constructed, not machine-checked. The task also prohibits running Django's test suite, so runtime confirmation remains pending outside this session.

The audit covers the helper and direct model-rename use, not the entire migration autodetector.
