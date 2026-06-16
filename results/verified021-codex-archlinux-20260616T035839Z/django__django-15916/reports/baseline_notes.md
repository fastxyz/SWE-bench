# Baseline Notes

## Root Cause

`modelform_factory()` always added a top-level `formfield_callback` attribute to
the generated form class, even when the caller omitted the argument and the value
was the default `None`. `ModelFormMetaclass` popped that class attribute before
building fields and treated it as the callback to use. As a result, the explicit
`None` from the factory masked any `formfield_callback` declared on the base
form's `Meta` class.

The metaclass also did not read `formfield_callback` from the `Meta` class of
the form currently being created. That meant `Meta.formfield_callback` was not
handled like other ModelForm `Meta` options during normal form construction.

## Changed Files

`repo/django/forms/models.py`

- Added `formfield_callback` to `ModelFormOptions` so the option is captured
  from the resolved inner `Meta` class and then updated to the callback that is
  actually used for field generation.
- Changed `ModelFormMetaclass` so a top-level `formfield_callback` class
  attribute remains an explicit override, but otherwise the callback is resolved
  from `Meta.formfield_callback`, falling back to a base form callback when the
  new `Meta` class does not define or inherit one.
- Changed `modelform_factory()` so it only installs a top-level
  `formfield_callback` override when the caller supplied a non-`None` callback.
  This prevents the factory default from masking a callback inherited from the
  base form's `Meta`.
- Changed the factory's assignment of `Meta.formfield_callback` to use
  `is not None`, preserving explicit falsey callable objects for consistency.

## Assumptions and Alternatives

I assumed `Meta.formfield_callback` should behave like the other ModelForm
`Meta` options: it can be declared on the current form, inherited from a parent
`Meta`, or inherited from the base form when a replacement `Meta` class omits
the option. An explicit top-level `formfield_callback` class attribute remains
the strongest override because existing code already supported that path.

I considered changing only `modelform_factory()` to stop passing
`formfield_callback=None`. That would fix the factory masking case, but it would
not allow a standalone `ModelForm.Meta.formfield_callback` declaration to affect
the fields for that same form. I rejected that narrower change because the issue
asks to support the `Meta` option itself for consistency.

I did not modify tests, documentation, or unrelated formset code. I also did not
run tests or project code, per the task constraints.
