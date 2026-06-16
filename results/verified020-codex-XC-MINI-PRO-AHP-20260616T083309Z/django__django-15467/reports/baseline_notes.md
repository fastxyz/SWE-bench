# Baseline Notes

## Root cause

`ModelAdmin.formfield_for_foreignkey()` replaces `empty_label` whenever it assigns
`AdminRadioSelect` for a `ForeignKey` listed in `radio_fields`. For nullable/blank
foreign keys, that branch unconditionally set `kwargs["empty_label"]` to
`_("None")`, which discarded an `empty_label` supplied by an overriding
`formfield_for_foreignkey()` implementation before calling `super()`.

## Changed files

`repo/django/contrib/admin/options.py`

Preserve a caller-provided `empty_label` when the admin radio widget is selected
for a blank `ForeignKey`. If no `empty_label` is present, the admin continues to
use the existing translated `"None"` default. Nonblank radio foreign keys still
force `empty_label` to `None`, matching the previous behavior and
`ModelChoiceField`'s handling of nonblank radio selects.

## Assumptions and alternatives considered

I assumed that `empty_label` passed in `kwargs` should take precedence whenever it
is explicitly provided, including values such as `None` or an empty string. Those
values are meaningful to `ModelChoiceField`, so the implementation uses
`kwargs.get("empty_label", _("None"))` rather than `kwargs.get("empty_label") or
_("None")`.

I considered changing the branch to only set `empty_label` when the key is absent,
but keeping the assignment expression preserves the existing explicit `None`
behavior for nonblank fields in the same place. I also considered changing
choice-field radio handling, but the reported issue and root cause are specific
to foreign-key radio fields.
