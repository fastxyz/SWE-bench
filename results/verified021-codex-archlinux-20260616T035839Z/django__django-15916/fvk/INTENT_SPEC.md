# INTENT_SPEC.md

Status: intent-only; written before accepting candidate behavior as correct.

1. A `ModelForm` inner `Meta` class may declare `formfield_callback`; that
   callback must be used when generating model-backed form fields.
2. `modelform_factory(model, form=BaseForm)` with no callback argument must
   preserve a callback available through `BaseForm.Meta.formfield_callback`.
3. A non-`None` `formfield_callback` argument to `modelform_factory()` remains
   an explicit override of any callback inherited through the base form's
   `Meta`.
4. `formfield_callback=None` as the factory default means "no explicit factory
   override." It must not mask inherited `Meta` behavior.
5. A top-level class attribute named `formfield_callback` remains an explicit
   metaclass override, because the pre-existing implementation exposed that
   path and public tests rely on factory-created explicit callbacks.
6. `formfield_callback` should behave consistently with other `ModelForm`
   `Meta` options: normal Python inner-class resolution applies. A subclass
   with no `Meta` uses the first parent's `Meta`; a subclass with a replacement
   `Meta` uses that replacement and does not receive an isolated callback
   fallback from the base `Meta`.
7. A falsey but non-`None` callable passed to `modelform_factory()` is still an
   explicit callback argument.
8. Non-callable callback objects must still flow to the existing
   `fields_for_model()` validation and raise the existing `TypeError`.
9. Public signatures and delegation through model formset factories must remain
   compatible.
