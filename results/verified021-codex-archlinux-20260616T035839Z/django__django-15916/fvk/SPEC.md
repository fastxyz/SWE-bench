# SPEC.md

Status: constructed, not machine-checked.

## Scope

This FVK pass specifies the callback-resolution slice changed in
`repo/django/forms/models.py`:

- `ModelFormOptions.__init__()` must retain `Meta.formfield_callback`.
- `ModelFormMetaclass.__new__()` must pass the intended callback to
  `fields_for_model()`.
- `modelform_factory()` must not mask a callback inherited from the base form's
  `Meta` when the caller omits `formfield_callback`.

The model abstracts away full Python class construction and Django field
generation. It represents only whether a top-level callback override exists,
what the resolved inner `Meta` class exposes, and which callback is finally
used for model-field construction.

## Public Intent Ledger

### E1: Issue Reproduction

- Source: prompt
- Evidence: "When no callback is provided the class uses no callback instead of
  the formfield_callback of the base form provided."
- Obligation: Calling `modelform_factory(model, form=BaseForm)` with no
  callback argument must not introduce a top-level `None` override. The
  generated form must use the callback available on `BaseForm.Meta`.
- Status: encoded by claim `FACTORY-OMITTED-PRESERVES-META`.

### E2: Expected Result

- Source: prompt
- Evidence: "The expected behavior would be that the FactoryForm uses the
  formfield_callback specified in the Meta attribute of MyForm."
- Obligation: `Meta.formfield_callback` is a valid source for the callback used
  by `fields_for_model()`.
- Status: encoded by claims `META-DIRECT` and
  `FACTORY-OMITTED-PRESERVES-META`.

### E3: Consistency With Other Meta Options

- Source: prompt hint
- Evidence: "we should support it for consistency with other Meta options"
- Obligation: The callback option should be resolved from the same inner
  `Meta` object used by other `ModelFormOptions`, not by a special base-class
  scan with different inheritance behavior.
- Status: encoded by claims `INHERITED-META-PRESERVES` and
  `REPLACED-META-DOES-NOT-LEAK-BASE`.

### E4: ModelForm Inheritance Rules

- Source: docs
- Evidence: `repo/docs/topics/forms/modelforms.txt` says normal Python name
  resolution applies: the child's `Meta`, if present, otherwise the first
  parent's `Meta`.
- Obligation: A subclass that replaces `Meta` without inheriting or defining
  `formfield_callback` must not receive only that option from a base `Meta`.
  A subclass without its own `Meta` still receives the first parent's `Meta`.
- Status: encoded by claims `INHERITED-META-PRESERVES` and
  `REPLACED-META-DOES-NOT-LEAK-BASE`. This obligation produced Finding F1 and
  the V2 source refinement.

### E5: Explicit Factory Callback

- Source: docs and public tests
- Evidence: `modelform_factory(..., formfield_callback=None)` documents a
  callable argument; public tests assert that an explicit provided callback is
  used and that a non-callable value still raises.
- Obligation: A non-`None` callback supplied to the factory must be an explicit
  override and must still reach the existing callability validation in
  `fields_for_model()`.
- Status: encoded by claims `FACTORY-EXPLICIT-OVERRIDES-META` and
  `TOP-LEVEL-OVERRIDE`.

### E6: Falsey But Non-None Callback Objects

- Source: default Python domain assumption
- Evidence: Python callables can define `__bool__()` and be falsey while still
  being non-`None` and callable.
- Obligation: The factory should distinguish "omitted/default `None`" from
  "explicit object", not truthiness.
- Status: encoded by claim `FACTORY-FALSEY-NON-NONE-OVERRIDES`.

## Formalized Contract

Let `resolve(top_attr, meta_cb)` model the metaclass callback selection:

- If the class attributes contain a top-level `formfield_callback`, use that
  value, even if it is `None`.
- Otherwise, use `formfield_callback` from the resolved inner `Meta` object.

Let `factoryClassAttrs(factory_arg, inherited_meta_cb)` model the factory:

- If `factory_arg` is `None`, create no top-level callback override and allow
  the generated `Meta` class to inherit `inherited_meta_cb`.
- If `factory_arg` is not `None`, install the explicit callback both on the
  generated `Meta` class and as the top-level metaclass override.

Let `childWithInheritedMeta(base_cb)` model a subclass that does not define its
own `Meta`. It resolves to `base_cb`.

Let `childWithReplacedMeta(base_cb)` model a subclass that defines a replacement
`Meta` with no callback. It resolves to `None`, not `base_cb`.

## Frame Conditions

- Field, exclude, widget, localization, label, help-text, error-message, and
  field-class option handling is unchanged.
- Existing `fields_for_model()` callability validation is unchanged. The
  metaclass only chooses which object is passed to it.
- `modelformset_factory()` and `inlineformset_factory()` preserve their public
  signatures and continue to delegate callback selection through
  `modelform_factory()`.

## Adequacy Notes

The K model in `fvk/mini-python-form-callback.k` is a deliberately small
semantics for callback selection. It is adequate for the reported bug because
the issue's observable failure is exactly the wrong callback object reaching
field generation. It is not a proof of all Django form behavior.
