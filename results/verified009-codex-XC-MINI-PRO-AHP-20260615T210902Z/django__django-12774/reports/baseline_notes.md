Root cause
==========

`QuerySet.in_bulk()` only accepted a non-primary-key `field_name` when
`model._meta.get_field(field_name).unique` was true. A field can also be
globally unique when the model declares an unconditional single-field
`UniqueConstraint`, but `in_bulk()` did not inspect those constraints and raised
`ValueError` for such fields.

Changed files
=============

`repo/django/db/models/query.py`

Updated `QuerySet.in_bulk()` to resolve the requested field once and accept it
when either the field has `unique=True` or the model has an unconditional
single-field `UniqueConstraint` for that field. The code reuses
`Options.total_unique_constraints`, which already filters out conditional
constraints, and compares against the resolved field's `name` so relation
attnames such as `author_id` can still map to constraints declared on
`author`.

Assumptions and alternatives
============================

I assumed `in_bulk()` must only accept keys that are unique across all rows,
because it returns a dictionary keyed by one field value. Therefore,
conditional `UniqueConstraint`s are still rejected because duplicate values can
exist outside the condition.

I considered accepting any field listed in a multi-field `UniqueConstraint`,
but rejected that because an individual field in a composite constraint is not
unique by itself. Only constraints with exactly one field are treated as
equivalent to `unique=True`.

I also considered changing `Options.total_unique_constraints` or adding a new
metadata helper, but the issue is localized to `in_bulk()` validation and the
existing helper already provides the needed list of unconditional constraints.
