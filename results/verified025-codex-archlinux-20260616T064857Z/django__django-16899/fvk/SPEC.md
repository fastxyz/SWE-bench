# FVK Spec

Status: constructed, not machine-checked.

## Scope

This specification covers the V1 fix for
`BaseModelAdminChecks._check_readonly_fields_item()` and the indexed label that
`_check_readonly_fields()` passes to it. The target observable is the
user-facing `admin.E035` message for invalid `readonly_fields` entries.

The generated formal core is:

- `fvk/mini-admin-checks.k`
- `fvk/readonly-fields-spec.k`

The adequacy artifacts are:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Public intent ledger

E-01: The prompt says the current message "would indicate the index of the value
at fault but it will not include the field's name." Obligation: preserve the
index and include the invalid field value.

E-02: The prompt shows the legacy message
`The value of 'readonly_fields[0]' is not a callable, an attribute of 'CityInline', or an attribute of 'admin_checks.City'.`
Obligation: treat this as the bug symptom, not the desired postcondition.

E-03: The prompt compares neighboring checks:
`The value of 'list_editable[0]' refers to 'original_release', which is not contained in 'list_display'.`
Obligation: use the "refers to '<field name>'" message shape for
`readonly_fields`.

E-04: The prompt says to "include the field name in the readonly_fields checks."
Obligation: every invalid-entry `admin.E035` message includes the invalid value.

E-05: Source code accepts callables, admin attributes, model attributes, and
model fields. Obligation: preserve those no-error cases.

E-06: Source code constructs `checks.Error` with `id="admin.E035"` and
`obj=obj.__class__`. Obligation: preserve the error id and ownership metadata.

E-07: The checks reference documents `admin.E035`. Obligation: update public docs
when the message changes.

E-08: Public tests assert the old message. Obligation: mark as SUSPECT legacy
evidence because the issue identifies that omission as the bug.

## Contract

C-01. Invalid item contract: for any invalid `readonly_fields` item with indexed
label `L`, field value `F`, admin class name `A`, and model label `M`, the item
check returns one `admin.E035` error whose message is represented as
`readonlyE035(L, F, A, M)`.

C-02. Indexed caller contract: for any non-negative index `I`, an invalid item
checked through the caller has label `readonlyLabel(I)` and still includes the
same field value `F` in the `admin.E035` message.

C-03. Frame contract: callables, admin attributes, model attributes, and model
fields remain valid and return no errors.

C-04. Metadata contract: the source continues to use `admin.E035` and
`obj=obj.__class__`.

C-05. Documentation contract: the public checks reference describes the same
message shape as the runtime behavior.

## Domain and side conditions

`readonly_fields` indexes are non-negative because Python enumeration starts at
zero and increments by one. The item-level contract assumes the label has
already been constructed by `_check_readonly_fields()`.

The model abstracts `checks.Error.msg` as `readonlyE035(label, field, admin,
model)`. This is sufficient for this issue because the old and new behaviors
differ exactly on whether `field` is part of the message representation.

## Branch coverage

The formal claims cover the invalid branch and all success branches in the
changed function. There is no loop in `_check_readonly_fields_item()`, so no loop
circularity is required.
