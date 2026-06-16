# Public Compatibility Audit

Status: constructed from source inspection; no code was executed.

## Changed public symbol

`django.forms.formsets.BaseFormSet.add_fields(self, form, index)`

- Signature: unchanged.
- Return value: unchanged (`None`; mutates `form.fields`).
- Dispatch shape: unchanged. Subclasses that call `super().add_fields(form,
  index)` continue to call the same method with the same arguments.
- `index=None` convention: preserved.

## Public callers and overrides inspected

- `BaseFormSet._construct_form()` calls `self.add_fields(form, i)` for numeric
  indexes. The numeric behavior is preserved.
- `BaseFormSet.empty_form` calls `self.add_fields(form, None)`. This is the
  repaired path.
- `BaseModelFormSet.add_fields()` delegates to `super().add_fields(form, index)`
  after primary-key field handling and already handles `index is None` for the
  primary-key lookup.
- `BaseInlineFormSet.add_fields()` delegates to `super().add_fields(form,
  index)` and then adds the inline foreign-key field.
- Public docs show subclass overrides of `add_fields(form, index)` calling
  `super().add_fields(form, index)`. The patch does not require override
  changes.

## Compatibility verdict

No public API, callsite, override, producer/consumer shape, or storage format
change is introduced by V1. Compatibility audit passes.
