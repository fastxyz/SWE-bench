# Baseline Notes

## Root cause

`ModelAdmin._get_edited_object_pks()` builds a regular expression from the
formset prefix and the model primary key field name:

```python
r'{}-\d+-{}$'.format(prefix, self.model._meta.pk.name)
```

The formset prefix is allowed to contain arbitrary characters. When it contains
regular expression metacharacters, those characters are interpreted as regex
syntax instead of literal POST field name text. As a result, admin
`list_editable` POST handling can collect the wrong primary key values, or miss
the intended values, before constructing the queryset used by the formset.

## Changed files

`repo/django/contrib/admin/options.py`

Escaped the dynamic regex fragments in `_get_edited_object_pks()` with
`re.escape()`. This preserves the existing regex-based matching logic while
making custom formset prefixes, and the primary key field name, match literally.

`reports/baseline_notes.md`

Added this required report describing the cause, the patch, and the assumptions
behind the fix.

## Assumptions and rejected alternatives

I treated the referenced `pk_pattern` code as the authoritative target even
though the issue title mentions the changeform view. The referenced method is
used by admin `list_editable` changelist POST handling.

I assumed the primary key field name is normally safe, as noted in the issue,
but escaped it anyway because it is also interpolated as a literal regex
fragment and escaping it does not change valid field-name behavior.

I considered replacing the regex with manual string splitting or prefix/suffix
checks, but rejected that as broader than necessary. The existing expression
already captures the intended field-name shape; escaping the dynamic fragments
is the minimal targeted fix.

No tests or project code were run, per the benchmark instructions.
