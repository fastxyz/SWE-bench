# Baseline Notes

## Root cause

`ImageField.contribute_to_class()` connected `update_dimension_fields()` to the
model's `post_init` signal for every concrete model that used an `ImageField`.
When an `ImageField` didn't define `width_field` or `height_field`, the receiver
was still called for each model instance even though `update_dimension_fields()`
immediately returned after checking that no dimension fields existed. This made
model initialization pay unnecessary signal dispatch overhead.

## Changed files

- `repo/django/db/models/fields/files.py`: Added the same dimension-field
  condition to the `post_init` connection path that `update_dimension_fields()`
  already used at runtime. Now the signal receiver is registered only for
  concrete models whose `ImageField` declares `width_field` or `height_field`.

## Assumptions

- `post_init` is only required for ImageField dimension maintenance when at
  least one dimension field is configured.
- Assignment-time dimension updates remain covered by `ImageFileDescriptor`,
  which still calls `update_dimension_fields(force=True)` after normal model
  initialization when an image value is assigned.
- Falsy `width_field` and `height_field` values should be treated the same way
  as the existing `update_dimension_fields()` and `deconstruct()` logic treats
  them: as no configured dimension field.

## Alternatives considered

- Leaving the signal connected and relying on the early return in
  `update_dimension_fields()` was rejected because that is the reported
  performance problem.
- Removing the `post_init` hook entirely was rejected because it is still needed
  for models with dimension fields, including cases where dimension fields are
  declared after the corresponding `ImageField`.
- Moving the dimension-field check into signal dispatch or model initialization
  was rejected as too broad for a field-specific no-op registration issue.
