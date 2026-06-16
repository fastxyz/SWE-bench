# Intent Spec

Status: constructed from public evidence, not machine-checked.

## Scope

The audited unit is `ModelChoiceField.to_python()` and the associated
`ModelChoiceField.default_error_messages['invalid_choice']` value in
`repo/django/forms/models.py`.

## Intent-only obligations

I-001. For an invalid non-empty submitted choice, `ModelChoiceField` must raise
`ValidationError` with code `invalid_choice`.

I-002. The `invalid_choice` `ValidationError` must carry the offending value in
`params` so a custom error message containing `%(value)s` can interpolate it.

I-003. The default `invalid_choice` message for `ModelChoiceField` must display
the offending value, matching the behavior of `ChoiceField` and
`ModelMultipleChoiceField`.

I-004. Existing non-error behavior must be preserved: empty values still clean
to `None`, and valid queryset values still clean to the matching model
instance.

I-005. The public constructor, method signatures, return shape on success, and
exception code must remain backward-compatible. Supplying `params` is an
intentional public behavior change for the error object.

I-006. Existing public tests or examples that assert the old default message
without a value are suspect evidence because the issue identifies that old
behavior as the bug.

