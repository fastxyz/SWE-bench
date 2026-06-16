# Baseline Notes

## Root cause

`Query.has_select_fields` was a computed property based on low-level SELECT
state: `select`, `annotation_select_mask`, and `extra_select_mask`. That made
the `__in` lookup skip its automatic RHS narrowing to the primary key whenever
an annotation mask existed.

Mixing `annotate()` and `alias()` can materialize `annotation_select_mask`
without a user-facing `values()` or `values_list()` selection. In that state the
RHS query still has no explicit selected fields, but `has_select_fields` returned
true, so `In.get_prep_lookup()` did not clear the RHS SELECT list and replace it
with the primary key. The resulting subquery could return all model columns plus
annotations, causing databases to reject the `IN` subquery for returning more
than one column.

## Files changed

`repo/django/db/models/sql/query.py`

- Replaced the inferred `has_select_fields` property with explicit query state
  that defaults to `False`.
- Set `has_select_fields = True` in `Query.set_values()`, which is the path used
  by `values()` and `values_list()` to define an explicit SELECT list.
- This separates "a query has internal annotation masks" from "the user selected
  specific RHS fields", allowing `__in` to keep defaulting unselected RHS queries
  to the primary key.

`repo/django/db/models/fields/related_lookups.py`

- Changed `RelatedIn.get_prep_lookup()` to call `set_values([target_field])`
  instead of manually clearing the SELECT clause and adding the target field.
- With `has_select_fields` now explicit, the related lookup must use the same
  selection path as `values()` so the base `In` lookup does not subsequently
  overwrite a relation-specific target field with `pk`.

## Assumptions and rejected alternatives

- I assumed `has_select_fields` is intended to mean "an explicit values-style
  selection exists" for lookup preparation, not merely "some SQL SELECT state is
  currently populated".
- I left the base `In` and `Exact` automatic primary-key selection paths using
  `clear_select_clause()` plus `add_fields(["pk"])`. Those paths inject default
  lookup behavior rather than record an explicit values-style selection, and no
  later base lookup step depends on their flag being changed.
- I considered trying to refine the old property to ignore annotation masks that
  came from `alias()`, but that would keep coupling lookup behavior to annotation
  internals and could misclassify other mask states. Explicit state set by
  `set_values()` is narrower and matches the issue's expected behavior.
- I did not modify tests or run the test suite, in accordance with the benchmark
  instructions.
