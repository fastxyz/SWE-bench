# Public Compatibility Audit

Changed public symbol: `django.forms.models.construct_instance`.

## Signature

Before and after:

```python
def construct_instance(form, instance, fields=None, exclude=None):
```

Status: compatible. V1 does not add parameters, change the return type, or
change call sites.

## Hook Calls

- `form[f.name].field.widget.value_omitted_from_data(form.data, form.files, form.add_prefix(f.name))`
  remains the same hook call shape as the original default-preservation branch.
- `form_field.empty_values` is read from the existing form field object. This is
  existing public `forms.Field` state derived from `validators.EMPTY_VALUES`.
- `f.save_form_data(instance, cleaned_data[f.name])` is unchanged for normal
  fields.
- File fields still use `file_field_list` and the later `save_form_data()` loop.

Status: compatible.

## Public Overrides and Subclasses

The patch does not add a new virtual method call, keyword argument, or override
requirement. Existing widgets that override `value_omitted_from_data()` keep
their behavior because their boolean result is still the source of omission
truth.

Status: compatible.

## Producer/Consumer Shape

The producer is `form.cleaned_data`; the consumer is the model field's existing
`save_form_data()` implementation. V1 changes only the skip predicate for
defaulted omitted fields; it does not change the data shape passed to consumers.

Status: compatible.
