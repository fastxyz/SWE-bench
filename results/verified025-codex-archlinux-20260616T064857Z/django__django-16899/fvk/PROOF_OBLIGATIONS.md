# Proof Obligations

Status: constructed, not machine-checked.

## PO-01: Invalid item message includes the field value

Source: E-01, E-03, E-04.

Claim: when `_check_readonly_fields_item()` reaches the invalid branch, the
`admin.E035` message representation is `readonlyE035(label, field_name,
admin_name, model_label)`.

Discharge: `readonly-fields-spec.k` claim 1 and the source code at
`repo/django/contrib/admin/checks.py` interpolate `field_name` into the message.

Status: discharged by construction.

## PO-02: Invalid item message preserves the indexed label

Source: E-01, E-02.

Claim: the indexed option label, such as `readonly_fields[0]`, remains in the
same `admin.E035` message.

Discharge: `readonly-fields-spec.k` claim 2 models caller label propagation as
`readonlyLabel(index)`, and the source still passes `label` as the first message
argument.

Status: discharged by construction.

## PO-03: Valid readonly_fields entries remain accepted

Source: E-05.

Claim: callable entries, admin attributes, model attributes, and model fields
return no errors.

Discharge: `readonly-fields-spec.k` claims 3 through 6 model each success branch;
the V1 source change only changed the invalid branch message string.

Status: discharged by construction.

## PO-04: Error id and object metadata are preserved

Source: E-06.

Claim: invalid entries still produce `checks.Error` with `id="admin.E035"` and
`obj=obj.__class__`.

Discharge: source audit confirms V1 did not change these arguments.

Status: discharged by construction.

## PO-05: Public checks documentation matches runtime behavior

Source: E-07.

Claim: `docs/ref/checks.txt` describes `admin.E035` as referring to
`<field name>`.

Discharge: V2 updated the `admin.E035` docs entry.

Status: discharged by V2 documentation edit.

## PO-06: Legacy public tests do not override issue intent

Source: E-08.

Claim: tests that assert the old message are SUSPECT and cannot be used as the
desired postcondition.

Discharge: `SPEC_AUDIT.md` marks the legacy-test evidence as suspect; no test
files were edited.

Status: discharged as an audit decision.
