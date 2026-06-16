# ITERATION GUIDANCE

Status: constructed for audit; not machine-checked.

## Decision

Keep V1 unchanged.

## Rationale

V1 changed `FileField.deconstruct()` to select
`getattr(self, "_storage_callable", self.storage)` before the default-storage
comparison and to reuse that selected value for `kwargs["storage"]`.

This exactly discharges:

- O2, the reported callable-returning-default case;
- O3, default storage omission preservation;
- O4, direct non-default storage preservation;
- O5, callable non-default storage preservation;
- O6, public compatibility preservation.

The FVK findings do not identify a remaining source-code defect in the audited
scope. FVK-F5 records the no-change conclusion.

## Recommended tests for a future normal test-writing pass

Do not edit tests in this benchmark phase. In a normal development workflow, add
a focused regression test equivalent to:

- define a callable storage provider that returns `default_storage`;
- construct `FileField(storage=that_callable)`;
- assert `field.deconstruct()[3]["storage"] is that_callable`.

Also keep the existing callable-non-default deconstruction coverage.

## Machine-checking

The K artifacts were written but not executed. A later environment with K
installed can run the commands listed in `PROOF.md`. Until then, treat the proof
as constructed only and do not remove tests based on it.
