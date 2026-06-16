# Baseline Notes

## Root cause

`ModelAdmin.lookup_allowed()` normalizes lookup paths by omitting a field when
that field is the target field of the previous relation. This is needed for
aliases such as `employee__department__id`, where the final target field does
not add another relation beyond `employee__department`.

The same normalization was also applied when the target field was itself a
relation. For a model whose primary key is a `OneToOneField` or `ForeignKey`,
`restaurant__place__country` was treated as if `place` were only a target-field
alias of `restaurant`. That collapsed the path to `restaurant__country`, so the
configured `list_filter = ["restaurant__place__country"]` was not recognized as
allowing the lookup.

## Files changed

`repo/django/contrib/admin/options.py`

Updated `BaseModelAdmin.lookup_allowed()` to keep the existing collapsed
relation path while also tracking the actual resolved field path from the
lookup. The method now checks both forms against `list_filter`. It also checks
the actual path with trailing target-field aliases removed, preserving the
existing behavior for admin-generated parameters such as related-field filters
that append a target primary-key field.

## Assumptions

The intended behavior is that a field path explicitly present in
`ModelAdmin.list_filter` should be accepted by `lookup_allowed()` even when the
path includes a primary-key relation that is not a model-inheritance parent
link.

Existing target-field alias behavior should remain valid. For example, URL
parameters generated for a related list filter may include the related target
field, and those should still be accepted when the configured filter is the
relation path.

## Alternatives considered

One option was to stop omitting target fields when the target field is
relational and not a parent link. I rejected that because it would risk
disallowing existing admin-generated parameters for a direct relation whose
remote primary key is itself a relation.

Another option was to special-case `OneToOneField(primary_key=True)` without
`parent_link=True`. I rejected that as too narrow because the underlying issue
is the loss of the actual configured lookup path, and the same shape can occur
with other relational primary-key target fields.

No tests were run, per the task instructions.
