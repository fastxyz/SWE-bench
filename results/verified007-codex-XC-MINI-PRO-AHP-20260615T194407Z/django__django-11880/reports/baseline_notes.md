# Baseline Notes

## Root cause

`BaseForm.__init__()` creates per-instance fields with `copy.deepcopy(self.base_fields)`.
The base form field implementation, `Field.__deepcopy__()`, copied the field object,
the widget, and the validator list, but it did not copy `self.error_messages`.
Because `copy.copy(self)` preserves attribute references, every copied field shared
the same `error_messages` dictionary as the original field. Mutating
`form.fields[name].error_messages` on one form instance could therefore affect other
instances of the same form class.

## Changed files

`repo/django/forms/fields.py`

Added a deep copy of `self.error_messages` in `Field.__deepcopy__()`. This keeps the
existing deepcopy flow intact while ensuring copied fields have isolated error
message dictionaries, including any nested mutable values supplied by user code.

## Assumptions

The intended isolation boundary is the same as the existing field/widget isolation
created when forms copy `base_fields`: each copied form field should be independently
mutable by that form instance.

The `validators` behavior was left unchanged. The existing implementation copies the
validator list but not the validator objects, and the reported issue is specifically
about the mutable `error_messages` mapping.

## Alternatives considered and rejected

A shallow `dict.copy()` of `error_messages` would prevent top-level dictionary
mutations from leaking, but it would still share nested mutable message values. The
issue description calls out modifications to the error message itself, so a full
`copy.deepcopy()` is more appropriate.

Rebuilding `error_messages` from class defaults during deepcopy would risk changing
runtime customizations already applied to the field. Copying the current mapping
preserves the field's configured state while isolating it for the copied field.
