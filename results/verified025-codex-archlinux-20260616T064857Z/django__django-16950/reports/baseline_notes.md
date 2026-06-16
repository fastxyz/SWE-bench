# Baseline Notes

## Root cause

`BaseInlineFormSet.add_fields()` cleared the parent instance's related field
whenever that field had a Python default and the parent instance was being
added. This was intended for generated primary keys, where an unsaved value in
the inline's hidden foreign-key field should be ignored because the primary key
can be generated again during save.

For a foreign key that targets a non-primary unique field with `to_field`, that
same mutation is wrong. In the reported case, the parent model's non-PK
`UUIDField(default=uuid.uuid4, editable=False, unique=True)` was set to `None`
while inline forms were constructed. The admin then tried to save the parent
with its alternate UUID key erased, causing the inline add workflow to fail.

## Files changed

`repo/django/forms/models.py`

- Updated `BaseInlineFormSet.add_fields()` so defaulted primary keys keep the
  existing clearing behavior, but defaulted non-PK `to_field` values are left on
  the parent instance.
- For defaulted non-PK `to_field` values, the inline foreign-key form field gets
  an explicit empty initial value. This preserves the current behavior of not
  posting an unsaved generated value from the add form while avoiding mutation
  of the actual parent object.
- Updated `InlineForeignKeyField.__init__()` to respect an explicit `initial`
  value supplied by the formset instead of always overwriting it from the parent
  instance.

## Assumptions and alternatives considered

I assumed the intended behavior for generated primary keys should remain
unchanged because the surrounding comment and save path rely on primary-key
defaults being regenerated when the parent is saved.

I considered simply skipping the `setattr(..., None)` call whenever `to_field`
was present. That would preserve the parent UUID, but it would also render the
unsaved generated alternate key into the inline hidden field on an add form,
which could be posted back and compared against a newly constructed parent
instance. The chosen fix keeps that hidden initial value empty while preserving
the in-memory parent value.

I also considered broader changes to admin formset construction, but the bug is
in the generic inline formset field construction path and can be fixed locally
there without admin-specific logic.
