# Baseline Notes

## Root cause

Assigning a related model instance to a `ForeignKey` copies the related
object's current target value into the local `field.attname`. For a related
model whose primary key is a `CharField`, a newly constructed instance has the
field default of `""`, not `None`. If the primary key is filled in after the
assignment and the related object is saved before the parent, the parent still
has the stale empty string in its foreign key column.

`Model._prepare_related_fields_for_save()` already handles the same save-order
pattern when the local foreign key value is `None`: it uses the cached related
object's primary key after the related object has been saved. The check missed
other empty model-field values, so string primary keys initialized as `""` were
not refreshed.

## Files changed

`repo/django/db/models/base.py`

Changed `_prepare_related_fields_for_save()` to refresh the local relation
attname from the cached related object when the current value is in
`field.empty_values`, instead of only when it is `None`. This keeps the existing
unsaved-related-object guard intact because objects with `obj.pk is None` still
raise before this branch, while allowing empty string FK values produced by
assignment from an initially empty string primary key to be replaced by the
saved related object's primary key.

`reports/baseline_notes.md`

Added this report with the root cause, changed files, assumptions, and rejected
alternatives required by the benchmark task.

## Assumptions and rejected alternatives

Assumption: the stale empty string should be treated the same way as `None` only
in this save-preparation path, where Django knows a related object is cached and
has a non-`None` primary key. This matches the existing behavior for related
objects saved after assignment.

Alternative considered: update the forward relation descriptor to avoid copying
empty primary-key values at assignment time. I rejected this because descriptor
assignment currently mirrors the related object's value immediately, and
changing that would affect broader relation assignment semantics. The issue is
specifically that save preparation failed to reconcile a cached related object
after the related object gained its primary key.

Alternative considered: use `field.target_field.empty_values` instead of
`field.empty_values`. I rejected this for the minimal fix because the local
value being tested is stored on the relation field's `attname`, and Django's
base `Field.empty_values` covers the reported CharField primary-key case without
changing target-field-specific behavior for unrelated field classes.

No tests or code were run, per the task instructions.
