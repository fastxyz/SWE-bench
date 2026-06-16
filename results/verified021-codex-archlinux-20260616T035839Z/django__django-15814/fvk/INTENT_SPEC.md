# Intent Spec

Status: constructed, not machine-checked.

## Public intent

1. A queryset using `select_related()` and `only()` through a foreign key whose
   target is a proxy model must not crash during result population.
2. For the reported shape,
   `AnotherModel.objects.select_related("custom").only("custom__name")`, the
   related proxy instance must be selectable with enough columns to initialize
   it. That includes the explicitly requested related field and the related
   model primary key.
3. Proxy relations should behave like relations to their concrete model for
   field-loading masks, because proxy models do not add concrete database
   fields.
4. Existing non-proxy `select_related()` plus `only()` behavior must be
   preserved.
5. No public API, method signature, test file, or query construction contract is
   to change.

## Domain

The audited domain is valid Django model field paths handled by
`Query.deferred_to_data()` for `only()`/`defer()` masks, with the regression
focus on a `select_related()` path that traverses a relation to a proxy model and
then selects a concrete field on that related model.

Out of domain: invalid field names, database execution semantics, SQL backend
differences, query result ordering, termination/performance claims, and changes
to public tests.

