# Intent Specification

Status: constructed for audit; not machine-checked.

## Target

The audited unit is `ForeignKey.validate(value, model_instance)` in
`repo/django/db/models/fields/related.py`, plus the `ModelForm` path that calls
`model_instance.full_clean()` and reaches this validation.

## Intent-derived obligations

1. `ForeignKey.validate()` must validate related-object existence through the
   related model's `_base_manager`, not `_default_manager`.
2. If the related row exists through `_base_manager`, the submitted foreign key
   value must not be rejected merely because `_default_manager` filters that row
   out.
3. Model field validation remains ORM validation. It avoids database existence
   errors and does not encode business policy such as whether an object is
   archived.
4. Explicit relation constraints still apply: if `limit_choices_to` excludes a
   candidate, validation may reject it.
5. Existing non-manager behavior is preserved: parent-link foreign keys return
   early; `None` returns after normal field validation permits it; database
   routing still uses `router.db_for_read(..., instance=model_instance)`; invalid
   values still raise the existing `ValidationError`.

## Observed legacy behavior to check

Before V1, `ForeignKey.validate()` used `_default_manager`. For a related model
whose default manager filters `archived=False`, an archived related row selected
by a form field queryset based on `_base_manager` was rejected with an invalid
"does not exist" error. The public issue describes that behavior as the bug, so
it is not an acceptable specification.
