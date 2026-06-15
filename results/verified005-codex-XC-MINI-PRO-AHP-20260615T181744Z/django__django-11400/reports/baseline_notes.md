# Baseline Notes

## Root cause

`RelatedFieldListFilter.field_choices()` initialized `ordering` to an empty tuple and always passed it to `field.get_choices()`. The model field implementation calls `order_by(*ordering)`, so an empty tuple clears the related model's default `Meta.ordering` instead of allowing it to apply.

`RelatedOnlyFieldListFilter.field_choices()` also called `field.get_choices()` without an `ordering` argument. Because `get_choices()` defaults `ordering` to an empty tuple, related-only choices were never ordered by the related model admin ordering or the related model's `Meta.ordering`.

## Changed files

`repo/django/contrib/admin/filters.py`

- Added `RelatedFieldListFilter.field_admin_ordering()` to resolve ordering for related filter choices.
- `field_admin_ordering()` returns the related `ModelAdmin.get_ordering()` value when configured, otherwise it falls back to the related model's `Meta.ordering`.
- Updated `RelatedFieldListFilter.field_choices()` to use the helper before calling `get_choices()`.
- Updated `RelatedOnlyFieldListFilter.field_choices()` to pass the same resolved ordering while preserving its existing `limit_choices_to` restriction.

## Assumptions and alternatives

I assumed that an empty or `None` ordering from `ModelAdmin.get_ordering()` means "no admin-specific ordering", so the related model's `Meta.ordering` should apply. This matches the admin queryset behavior, where admin ordering is only applied when it is truthy and the default model ordering otherwise remains in effect.

I considered changing `Field.get_choices()` to avoid clearing default ordering when `ordering` is empty, but rejected that because it would broaden the behavior change beyond the admin list filters described in the issue. I also considered using the related admin's full queryset, but rejected that because the existing filter code only consults the related admin for ordering, not for filtering or other queryset customizations.
