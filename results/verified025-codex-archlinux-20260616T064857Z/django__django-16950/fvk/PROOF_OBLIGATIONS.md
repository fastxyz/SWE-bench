# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Preserve defaulted non-PK `to_field` values

For `self.instance._state.adding == True`, `to_field.has_default() == True`,
and `to_field.primary_key == False`, `BaseInlineFormSet.add_fields()` must not
write `None` to `self.instance.<to_field.attname>`.

Discharges findings: F-001.

## PO-002: Keep empty inline initial for defaulted non-PK `to_field`

For the same state as PO-001, the generated `InlineForeignKeyField` must have
`initial is None` so an unsaved generated alternate key is not rendered as the
hidden inline FK value.

Discharges findings: F-002.

## PO-003: Preserve defaulted primary-key behavior

For `self.instance._state.adding == True`, `to_field.has_default() == True`,
and `to_field.primary_key == True`, `BaseInlineFormSet.add_fields()` must keep
the legacy behavior: set the parent key attribute to `None`, and produce an
empty inline initial value.

Discharges findings: F-002.

## PO-004: Honor explicit initial without changing default derivation

`InlineForeignKeyField.__init__()` must use a caller-supplied `initial` when one
is present in `kwargs`, and must preserve the old parent-derived initial logic
when no explicit `initial` is present.

Discharges findings: F-002 and F-003.

## PO-005: Preserve validation comparison semantics

`InlineForeignKeyField.clean()` must continue to compare non-empty submitted
values against the current parent instance value (`to_field` when set, otherwise
`pk`) and continue to accept empty values according to existing `pk_field`
semantics.

Discharges findings: F-003.

## PO-006: Preserve downstream FK assignment for alternate keys

After `add_fields()`, `BaseInlineFormSet._construct_form()` must still read the
parent alternate key and assign it to the child form instance FK attname before
validation. This requires PO-001: the parent alternate key must still be present.

Discharges findings: F-001.

## PO-007: Public compatibility

The fix must not change public signatures, form field construction protocols, or
existing callsites that don't opt into explicit `initial`.

Discharges findings: F-003.

## PO-008: Honesty and reproducibility

The FVK proof must be labeled constructed, not machine-checked, and provide exact
non-executed K commands for later reproduction.

Discharges findings: F-004.
