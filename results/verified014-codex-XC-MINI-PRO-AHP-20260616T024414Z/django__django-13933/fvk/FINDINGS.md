# FVK Findings

Status: constructed, not machine-checked.

## Findings from formalization

### F-001: V1 closes the reported runtime defect

Input: a non-empty value such as `"4"` that is not in the field queryset.

Observed before V1: `ModelChoiceField.to_python()` raised
`ValidationError(self.error_messages['invalid_choice'], code='invalid_choice')`
without `params`, so custom messages using `%(value)s` could not display `"4"`.
The default message also had no `%(value)s` placeholder.

Expected: the `ValidationError` has code `invalid_choice`,
`params['value'] == "4"`, and the default message can display `"4"`.

Status: closed by V1. See PO-2 and PO-3.

### F-002: Legacy default-message expectations are suspect

Input: public tests or examples expecting
`"Select a valid choice. That choice is not one of the available choices."`
for `ModelChoiceField`.

Observed: that text is the exact behavior the issue asks to change.

Expected: tests for the new intent should expect a value-aware message such as
`"Select a valid choice. 4 is not one of the available choices."`

Status: not a source-code defect. It justifies not preserving the old default
message as an invariant. Test files were not edited.

### F-003: Custom messages with literal percent signs are a compatibility risk

Input: a custom `invalid_choice` message containing an unescaped literal `%`.

Observed after V1: because params are now supplied, Django's normal
`message % params` interpolation path is active for `ModelChoiceField`, as it
already is for `ChoiceField` and `ModelMultipleChoiceField`.

Expected: custom messages that contain literal percent signs should escape them
as `%%`, and custom messages that want the invalid value can use `%(value)s`.

Status: accepted. The public issue specifically requests params for
`ModelChoiceField`, and this aligns it with the existing choice-field
convention. See PO-6.

### F-004: Documentation coverage is incomplete but not a runtime blocker

Input: a reader consulting `docs/ref/forms/fields.txt` for
`ModelChoiceField.invalid_choice`.

Observed: the docs mention `%(value)s` for `ChoiceField`,
`MultipleChoiceField`, `TypedMultipleChoiceField`, and
`ModelMultipleChoiceField`, but the `ModelChoiceField` section does not mention
the placeholder.

Expected: documentation could be updated separately to describe the new
placeholder for `ModelChoiceField`.

Status: non-blocking for this benchmark repair. No docs were changed because
the issue's required runtime behavior is already satisfied by V1 and the task
requires a source fix plus FVK artifacts.

## Proof-derived findings from verify

### F-005: Constructed proof was not machine-checked

Input: the K artifacts in `fvk/`.

Observed: this session forbids running `kompile`, `kast`, `kprove`, tests, or
Python.

Expected: a later machine-checking pass would run the commands in `PROOF.md`
and expect `kprove` to return `#Top`.

Status: residual verification caveat, not a source-code defect.

