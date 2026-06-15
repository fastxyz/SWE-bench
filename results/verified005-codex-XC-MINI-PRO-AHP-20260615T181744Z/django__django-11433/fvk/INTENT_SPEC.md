# Intent Specification

Scope: the audited unit is the per-field assignment decision in
`construct_instance()` in `repo/django/forms/models.py`. The surrounding loop is
covered as a frame condition: every model field is processed independently, file
fields are deferred after non-file fields, and fields outside the ModelForm scope
remain skipped.

## Public Intent Obligations

I1. A ModelForm is constructed from `cleaned_data`.

Source: `construct_instance()` docstring, `repo/django/forms/models.py:31-34`.

Requirement: if a model field is editable, not an `AutoField`, included by
`fields`/`exclude`, and present in `cleaned_data`, then `cleaned_data` is the
candidate value for assignment to the model instance.

I2. Values deliberately placed in `cleaned_data` must be able to overwrite a
model field default even when that field was omitted from the submitted payload.

Source: `benchmark/PROBLEM.md`: "if 'some_field' isn't in the data payload ... and
'some_field' has a default value on the model, it cannot be overwritten with
'self.cleaned_data'."

Requirement: for an eligible field with a model default, `value_omitted_from_data`
true must not by itself skip assignment when `cleaned_data[f.name]` contains a
non-empty derived value.

I3. Ordinary omitted optional values that clean to an empty value preserve model
defaults.

Source: public tests `repo/tests/model_forms/tests.py:575-580`,
`repo/tests/model_forms/tests.py:663-666`,
`repo/tests/model_forms/tests.py:679-682`.

Requirement: for an eligible field with a model default, if the widget reports
the value omitted and the cleaned value is one of the form field's empty values,
`construct_instance()` must leave the model default intact.

I4. Submitted blank data is different from omitted data.

Source: public test `repo/tests/model_forms/tests.py:582-586`.

Requirement: if the field is present in the submitted payload, an empty cleaned
value is still assigned instead of preserving the model default.

I5. Widget omission semantics must remain authoritative.

Source: widget implementations and public tests:
`Widget.value_omitted_from_data()` returns `name not in data`
(`repo/django/forms/widgets.py:260-261`); checkbox and multiple-select widgets
return false for omission (`repo/django/forms/widgets.py:776-779`,
`repo/django/forms/widgets.py:753-756`), with tests at
`repo/tests/model_forms/tests.py:588-633`.

Requirement: `construct_instance()` must use each widget's
`value_omitted_from_data()` result. When a widget says the value is not omitted,
the default-preservation skip must not apply.

I6. File fields keep their existing delayed assignment behavior.

Source: `construct_instance()` comment and branch at
`repo/django/forms/models.py:56-64`; `FileField.save_form_data()` distinguishes
`None` as "no change" and other false values as "clear" at
`repo/django/db/models/fields/files.py:309-317`.

Requirement: a file field that passes the default-preservation check is queued
for the existing delayed save path; it must not be assigned early.

I7. Public API compatibility must be preserved.

Source: no issue text requests API changes; `construct_instance(form, instance,
fields=None, exclude=None)` is a public helper exported from
`django.forms.models`.

Requirement: no signature, return type, field hook signature, or widget hook
signature change is allowed for this fix.

## Residual Ambiguity

A1. The public issue does not say whether an explicit `clean()` assignment of an
empty value such as `''` or `None` should override a model default when the raw
payload omitted the field. Public tests require preserving defaults for ordinary
omitted values that naturally clean to empty values. Because `cleaned_data` does
not record whether an empty value was produced by normal field cleaning or
manually re-assigned to the same empty value, this point is underspecified and
must not drive a broader source change without more public intent.
