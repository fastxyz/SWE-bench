# Baseline Notes

## Root cause

When a new concrete model subclass is created in the same migration where a
same-named field is removed from one of its bases, the autodetector used to
emit the subclass `CreateModel` before the base `RemoveField`. Applying the
`CreateModel` first asks Django to render a subclass with a local field whose
name still exists on the base class in the current migration state, raising a
`FieldError`.

The migration dependency sorter already knows how to order operations around
removed fields, but `generate_created_models()` did not declare that a subclass
creation depends on removal of a clashing base field.

## Changed files

`repo/django/db/migrations/autodetector.py`

Added removed-field dependencies while building a new model's `CreateModel`
operation. For each concrete string base, the autodetector now checks fields
removed from that base in the same change set and, when the new subclass
declares a field with the same name, adds a dependency on that base
`RemoveField`. This lets the existing topological ordering place the
`RemoveField` before the subclass `CreateModel`, including the case where more
than one new subclass depends on the same base field removal.

## Assumptions and alternatives

I assumed the correct behavior is to generate an applyable migration order while
preserving Django's existing warning-free behavior about data loss. The issue
description and public hints favor ordering the operations rather than blocking
or prompting the user.

I considered changing `check_dependency()`, but it already recognizes removed
field dependencies in the form `(app_label, model_name, field_name, False)`.
The missing piece was declaring that dependency on the new subclass operation.

I also considered depending on every removed field from each base. The final
change is narrower: it only depends on removed base fields whose names are also
declared locally by the new subclass, because unrelated base field removals do
not cause the field-clash error and should not constrain ordering.

No tests were run because the task instructions prohibit running tests or code
in this benchmark workspace.
