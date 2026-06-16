# Intent Spec

Status: constructed from public intent, not machine-checked.

## Required Behavior

I1. Removing a `unique_together` entry must remove the database constraint that
Django generated for that `unique_together` entry.

I2. For a single-field `unique_together`, a field-level `unique=True`
constraint or a primary key on the same column must not cause migration failure
and must not be dropped as the `unique_together` constraint.

I3. The concrete reported migration must not raise
`ValueError: Found wrong number (2) of constraints` merely because the same
column has both a primary key and the generated single-field `unique_together`
constraint.

I4. Explicit `Meta.constraints` and `Meta.indexes` remain protected from
implicit `unique_together` deletion.

I5. Existing schema-editor override/call compatibility should be preserved where
the fix does not require an API/signature change.

## Ambiguous Or Follow-Up Intent

A1. The public issue discussion mentions adding a single-field
`unique_together` after `unique=True` as another possible manifestation, but a
later public hint says that creation path could not be reproduced and frames the
draft fix around removing the constraint by generated name. This audit treats
creation-path behavior as a follow-up ambiguity, not as a required change for
this fix.

A2. Manually renamed single-field `unique_together` constraints are not clearly
covered. The public hint explicitly accepts relying on Django-generated
`unique_together` names even if that breaks dropping a manually renamed
constraint in ambiguous cases.
