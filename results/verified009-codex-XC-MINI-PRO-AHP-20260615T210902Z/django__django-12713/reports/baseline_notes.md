# Baseline Notes

## Root cause

`BaseModelAdmin.formfield_for_manytomany()` assigned Django admin's special many-to-many widgets unconditionally when the field appeared in `autocomplete_fields`, `raw_id_fields`, `filter_vertical`, or `filter_horizontal`. This overwrote an explicit `widget` passed through `kwargs`. `formfield_for_foreignkey()` already avoids this by only assigning its default admin widget when `widget` is absent, so the two hooks had inconsistent precedence.

## Files changed

`repo/django/contrib/admin/options.py`

- Updated `BaseModelAdmin.formfield_for_manytomany()` to guard the admin widget selection with `if 'widget' not in kwargs:`.
- Left queryset selection and post-processing of select-multiple help text unchanged so the existing many-to-many formfield behavior is preserved apart from honoring explicit widget overrides.

## Assumptions

- A caller-provided `widget` should take precedence over ModelAdmin widget options, matching `formfield_for_foreignkey()`.
- The issue concerns the hook's `widget` keyword argument and not other keyword arguments such as `queryset`, whose existing precedence was already guarded.
- Existing admin widget defaults should still apply when no explicit `widget` is supplied.

## Alternatives considered and rejected

- Removing admin widget assignment entirely for many-to-many fields was rejected because it would break `autocomplete_fields`, `raw_id_fields`, and filtered select configuration when callers do not pass a widget.
- Adding a special case only for one admin option, such as `filter_horizontal`, was rejected because the same overwrite behavior existed for all of the many-to-many admin widget branches.
- Changing `formfield_for_dbfield()` was rejected because foreign key behavior was already correct and the defect was localized to `formfield_for_manytomany()`.

## Verification

No tests or project code were run, per the task instructions. The edited source was reviewed directly.
