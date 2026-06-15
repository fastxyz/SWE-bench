# Baseline Notes

## Root Cause

`SQLCompiler.find_ordering_name()` decides whether ordering by a related field
should expand to the related model's `Meta.ordering`. It already avoids that
expansion when the requested ordering names the foreign key's concrete attname,
for example `author_id`, because that means the query should order by the local
foreign key column directly.

For a multi-hop ordering such as `record__root_id`, `_setup_joins()` resolves
the final path segment `root_id` to the `root` `ForeignKey` field whose
`attname` is `root_id`. The compiler then compared `field.attname` with the
entire lookup string, `record__root_id`, instead of the final lookup segment.
That comparison failed, so Django treated the ordering as if it were
`record__root`, expanded the related model's default ordering, and introduced
the unnecessary self-join and inverted direction described in the issue.

## Changed Files

`repo/django/db/models/sql/compiler.py`

Changed the foreign-key-attname guard in `find_ordering_name()` to compare
`field.attname` with `pieces[-1]`, the final component of the ordering lookup,
instead of the full lookup name. This preserves the existing behavior for
single-segment orderings like `author_id` while applying the same rule to
joined paths such as `record__root_id`.

## Assumptions and Alternatives

I assumed that `order_by("record__root_id")` is intended to order by the
concrete `root_id` column reached through the `record` join, not by the
referenced `OneModel` row using `OneModel.Meta.ordering`. That matches Django's
existing special case for a direct foreign key attname.

I considered changing join trimming or self-referential foreign key handling,
but rejected that because the extra join is a consequence of incorrectly
expanding to related-model default ordering. Once `root_id` is recognized as an
attname, the existing `trim_joins()` path can order by the previous table's
foreign key column.

I also considered treating `record__root` and `record__root_id` the same, but
rejected that because ordering by the relation name is documented and expected
to use the related model's default ordering, while ordering by the attname is
the explicit request for the raw foreign key value.
