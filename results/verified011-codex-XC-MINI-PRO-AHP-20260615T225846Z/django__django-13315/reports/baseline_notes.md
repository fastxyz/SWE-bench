# Baseline Notes

## Root Cause

`django.forms.models.apply_limit_choices_to_to_formfield()` applied a model
field's `limit_choices_to` directly to the form field queryset with
`complex_filter()`. When `limit_choices_to` contains a `Q` object or lookup that
joins through a multi-valued relation, the SQL join can return the same related
model row more than once. Those duplicate queryset rows become duplicate
`ModelChoiceField` options and can also make `ModelChoiceField.to_python()` call
`.get()` against a queryset that returns multiple rows for one selected object.

## Changed Files

`repo/django/forms/models.py`

Reworked `apply_limit_choices_to_to_formfield()` so a non-empty
`limit_choices_to` is converted to a `Q` object and applied through a correlated
`Exists()` subquery constrained by `pk=OuterRef('pk')`. The outer form field
queryset is no longer joined directly to the relations referenced by
`limit_choices_to`, so multi-valued joins inside the limit condition cannot
duplicate the rendered choices. This also keeps validation from using a
duplicated queryset for `.get()`.

## Assumptions and Rejected Alternatives

I assumed the intended behavior is to preserve the existing form field queryset
as the outer queryset, including any manager filters, ordering, or custom
queryset supplied by a form field callback, while using `limit_choices_to` only
as an existence condition for each candidate object.

I considered adding `.distinct()` after `complex_filter()`, but rejected it
because the issue history explicitly notes that a previous distinct-based fix
was reverted after it caused database errors with custom model fields whose
selected values could not be compared by the backend.

I considered filtering duplicates in Python during choice iteration, but rejected
that because it would only address duplicate rendering. It would not fix the
same duplicated queryset being used by `ModelChoiceField.to_python()` for
validation.

I left test files unchanged as required by the task instructions and did not run
the test suite or project code.
