# Baseline Notes

## Root cause

`Subquery._resolve_output_field()` delegates to `Query.output_field`. For a
query with a single selected column, `Query.output_field` returned
`self.select[0].field`.

When the selected column is a `Col` for a `ForeignKey`, `.field` is the
expression output field and can resolve to the concrete target field, such as
the related model primary key. That causes an outer filter like
`filter(related=SimpleLazyObject(...))` to use the plain field lookup and call
the target field's `get_prep_value()` directly. For an integer primary key this
attempts `int(SimpleLazyObject(...))`, producing the reported `TypeError`.

The selected `Col` keeps the original model field on `.target`. Returning that
field preserves the relational output field for nested subqueries, so exact
lookups use Django's related lookup normalization and can unwrap model
instances before preparing the target value.

## Files changed

`repo/django/db/models/sql/query.py`

Changed `Query.output_field` to return `self.select[0].target` for single
selected columns instead of `self.select[0].field`. This matches nearby query
code that treats `query.select[0]` as a `Col` and reads `.target` when it needs
the actual selected field.

## Assumptions

`Query.select` entries in this branch are column expressions created by the
query's field selection machinery and therefore expose `.target`. The existing
code in `Query.trim_start()` already relies on that property for
`query.select[0]`.

The hidden tests cover the regression scenario, since adding or modifying tests
is forbidden for this benchmark.

## Alternatives considered

Changing lookup preparation to special-case `SimpleLazyObject` was rejected
because the failure is not specific to lazy objects. The real issue is that the
subquery reports the wrong output field and bypasses the related lookup path.

Changing `Subquery._resolve_output_field()` was rejected because `Query` is the
owner of the selected-field metadata. Fixing `Query.output_field` keeps all
single-column subquery output-field resolution consistent.
