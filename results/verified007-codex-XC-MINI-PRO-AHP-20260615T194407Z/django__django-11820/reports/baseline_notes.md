# Baseline Notes

## Root Cause

`Model._check_ordering()` validates `Meta.ordering` entries by splitting related
field paths and resolving each part with `Options.get_field()`. Unlike the query
resolver, this validation path did not treat `pk` as an alias for the current
model's concrete primary key. As a result, an ordering such as
`option__pk` reached the related model, attempted to resolve a literal field
named `pk`, and incorrectly raised `models.E015`.

## Changed Files

`repo/django/db/models/base.py`

The related-ordering validation now translates each path component named `pk`
to the current model's primary-key field name before calling `get_field()`. This
mirrors the behavior used by the ORM query resolver and allows `__pk` after a
relationship while preserving the existing validation of missing fields,
invalid transforms, and many-to-many ordering.

## Assumptions and Alternatives

I assumed the intended behavior is that `pk` should be accepted anywhere the ORM
would resolve it in an ordering path, including after a related field and when a
primary key itself is relational.

I considered special-casing only ordering strings that end with `__pk`, but
rejected that because the query resolver handles `pk` as a component of the path,
not as a suffix-only token. Resolving `pk` component-by-component is more
consistent and remains limited to the existing related-field validation loop.

I also considered replacing the checker with the query resolver, but rejected
that as a broader change than needed for this regression and more likely to
affect unrelated system-check behavior.
