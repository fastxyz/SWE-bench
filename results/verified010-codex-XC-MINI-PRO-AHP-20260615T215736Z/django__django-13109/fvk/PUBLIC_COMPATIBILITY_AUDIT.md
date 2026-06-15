# Public Compatibility Audit

Status: constructed for audit; not machine-checked.

## Changed public symbol

`django.db.models.fields.related.ForeignKey.validate(self, value, model_instance)`

- Signature: unchanged.
- Return shape: unchanged; the method still returns `None` on success and raises
  `ValidationError` on invalid input.
- Virtual dispatch: unchanged; no new arguments are passed to overridable
  methods.
- Query API shape: unchanged; the code still constructs a queryset, applies
  `filter()`, applies `complex_filter(limit_choices_to)`, and calls `exists()`.
- Database routing: unchanged; the call to `router.db_for_read()` remains the
  source of the database alias.

## Public call path

`ModelForm._post_clean()` constructs the model instance and calls
`instance.full_clean()`. `Model.clean_fields()` then calls each field's
`clean()`, which calls `validate()`. The change does not alter this call chain.

## Compatibility conclusion

The patch changes only which manager supplies the related-object existence
query. It does not change method signatures, exception types, error formatting,
or form construction APIs. The compatibility audit has no open blockers.
