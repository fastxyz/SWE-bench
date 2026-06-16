## Root cause

`BaseModelFormSet.save()` always calls `save_new_objects()` after saving existing
objects. Because bound model formsets derive `initial_form_count()` from the
submitted management form, a client can alter management form counts and cause
submitted model data to be handled as extra forms. Existing options such as
`extra=0`, `max_num`, and `validate_max` control display or validation counts,
but they do not provide an explicit save-time guard that prevents creation of
new model instances.

## Changed files

`repo/django/forms/models.py`

Added an `edit_only` flag to `BaseModelFormSet`, exposed it from
`modelformset_factory()` and `inlineformset_factory()`, and made
`save_new_objects()` return an empty `new_objects` list when `edit_only` is
enabled. Existing-object saves, deletions, validation, and `commit=False`
tracking remain on the existing code paths.

`repo/django/contrib/contenttypes/forms.py`

Added the same `edit_only` keyword to `generic_inlineformset_factory()` and
passed it through to `modelformset_factory()` so generic inline model formsets
can opt into the same save-time creation guard.

## Assumptions and alternatives considered

I assumed the requested feature should be an explicit opt-in mode rather than a
change to the default behavior, because model formsets normally support both
editing existing objects and adding new ones.

I considered solving the issue by changing management form count handling or by
making tampered extra forms invalid. I rejected that because it would alter
general formset validation semantics and could break existing uses that rely on
extra forms being validated but conditionally ignored by application code.

I also considered only changing `save()` to skip `save_new_objects()` when
edit-only mode is enabled. I kept the guard inside `save_new_objects()` instead
so direct callers of that method get the same protection and `new_objects` is
still initialized to an empty list.
