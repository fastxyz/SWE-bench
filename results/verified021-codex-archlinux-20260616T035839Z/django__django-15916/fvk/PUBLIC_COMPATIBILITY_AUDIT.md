# PUBLIC_COMPATIBILITY_AUDIT.md

Status: public compatibility audit.

## Changed Symbols

### `django.forms.models.ModelFormOptions`

- Change: stores a new `_meta.formfield_callback` attribute.
- Public compatibility: additive internal option storage; no signature change.
- Callers/consumers: `ModelFormMetaclass` uses the option when calling
  `fields_for_model()`.
- Status: compatible.

### `django.forms.models.ModelFormMetaclass.__new__`

- Change: resolves callback from an explicit top-level class attribute if
  present, otherwise from the resolved inner `Meta` object.
- Public compatibility: no signature change; class construction behavior is
  changed only for the issue's callback-selection path and the V1-only
  inconsistent fallback.
- Subclass/override audit: source search found no public overrides of
  `ModelFormMetaclass.__new__()` in the audited source. Existing custom
  metaclass use in public tests depends on `modelform_factory()` preserving
  `type(form)` construction, which is unchanged.
- Status: compatible.

### `django.forms.models.modelform_factory`

- Change: creates a top-level `formfield_callback` class attribute only for a
  non-`None` factory argument; sets `Meta.formfield_callback` for non-`None`
  rather than truthy arguments.
- Public compatibility: signature unchanged. Existing explicit callbacks and
  invalid callback validation are preserved. Omitted/default callback now allows
  inherited `Meta` behavior.
- Producer/consumer audit: `modelformset_factory()` and
  `inlineformset_factory()` continue to pass their callback argument through to
  `modelform_factory()` with unchanged signatures.
- Status: compatible.
