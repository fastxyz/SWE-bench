# FVK Notes

## Summary

FVK did not confirm V1 unchanged. It found one completeness gap: V1 only
inspected an explicit `widget` kwarg, but Django can still produce an effective
`RadioSelect` from a custom form field class default when no widget kwarg is
provided. V2 keeps the V1 behavior for the reported path and adds that missing
effective-widget fallback.

## Source Change

Changed `repo/django/db/models/fields/related.py`.

Decision: when `kwargs.get('widget')` is `None`, read the selected form field
class's default widget with:

`getattr(kwargs.get('form_class', forms.ModelChoiceField), 'widget', None)`

Reason: FVK-F1 showed that V1 failed PO7. `Field.__init__()` later uses
`widget or self.widget`, so the default widget is part of the actual rendered
widget decision. Without checking it, a non-blank foreign key using a custom
`ModelChoiceField` subclass with `widget = forms.RadioSelect` could still render
the blank radio option. The V2 fallback discharges PO1 and PO7 for both explicit
and form-class-default radio widgets.

Decision: keep the V1 guard that only writes `empty_label=None` when
`not self.blank` and `'empty_label' not in kwargs`.

Reason: FVK-F2 traces the original defect to PO1, PO2, and PO3: for non-blank
effective radio widgets, `empty_label=None` removes the iterator's empty choice
and prevents the new form's empty value from checking a blank radio input. PO4
requires `blank=True` radio fields to keep a blank choice because blank is then a
valid model-form value.

Decision: preserve normal select behavior.

Reason: PO5 comes directly from the issue text, which says the blank option is
idiomatic for select widgets even on required fields. The radio predicate keeps
non-radio widgets on Django's existing `ModelChoiceField.empty_label` default.

Decision: preserve explicit `empty_label` overrides.

Reason: FVK-F3 and PO6 classify explicit `empty_label` as a caller override
rather than a generated default. This matches Django's local `formfield()`
defaulting convention and keeps admin radio behavior compatible.

Decision: do not change the public method signature, queryset handling, or
`to_field_name` handling.

Reason: PO8 frames unrelated behavior. V2 still delegates through the same
`super().formfield()` call and only adds a generated default in the targeted
case.

## Verification Limits

FVK-F4 records that no tests, Python code, or K tooling were run because the task
forbids them. The proof artifacts are constructed, not machine-checked, and no
test removal is recommended.
