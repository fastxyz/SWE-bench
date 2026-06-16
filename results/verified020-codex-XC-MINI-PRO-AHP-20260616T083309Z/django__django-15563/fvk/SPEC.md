# FVK Specification

Status: constructed, not machine-checked.

## Scope

This FVK run verifies the update-planning slice touched by the fix:

- `SQLUpdateCompiler.pre_sql_setup()` selects a stable list of identifiers for
  the queryset model and for each ancestor model receiving a related update.
- `UpdateQuery.get_related_updates()` builds one ancestor-table update per
  related model and applies the correct `pk__in` filter for that model.

The proof abstracts away full Python execution, SQL generation, database
execution, backend-specific rowcount behavior, and tests. The retained observable
is the one the issue requires: which identifier list is used for each update
target.

## Intent ledger summary

- E1/E2 require that updating a field on `OtherBase` through `Child.objects`
  affects the `OtherBase` rows linked to those `Child` rows, not unrelated
  `OtherBase` rows whose primary keys happen to equal the child/base primary
  keys.
- E3-E6 require the implementation shape: `related_ids` is a dictionary keyed by
  ancestor model, populated from parent-link values and consumed as
  `related_ids[model]`.
- E7/E8 justify using Django's metadata path APIs for inherited parent links.

## Abstract state

- `PKIDS`: the ordered identifier list selected from the queryset model primary
  key.
- `RELATED_IDS[M]`: for each ancestor model `M` in `related_updates`, the ordered
  identifier list selected from the parent-link path from the queryset model to
  `M`.
- `PRIMARY_FILTER`: the filter applied back to the main update query.
- `RELATED_FILTERS[M]`: the `pk__in` filter applied to the related update for
  model `M`.

## Contract

For every queryset update over a concrete MTI model with related updates:

1. `pre_sql_setup()` selects `PKIDS` and every `RELATED_IDS[M]` from the original
   queryset before any update query executes.
2. The main update query is restricted with `PRIMARY_FILTER = pk__in(PKIDS)`.
3. For every related update target model `M`, `get_related_updates()` produces an
   update query with `RELATED_FILTERS[M] = pk__in(RELATED_IDS[M])`.
4. No related update target may use `PKIDS` unless `RELATED_IDS[M]` is equal to
   `PKIDS` because the model's parent link is the queryset primary key.
5. If the selected row set is empty, all identifier lists are empty and related
   updates filter with empty `pk__in` lists, so no ancestor rows are updated.

## Frame conditions

- The public `QuerySet.update()` API, update values, and existing related-update
  query coalescing remain unchanged.
- `related_ids` remains private `UpdateQuery` state.
- The proof does not assert any ordering beyond row-position alignment between
  selected rows and identifier lists. The code preserves that alignment by
  collecting all selected columns from the same result row.

## Compatibility

No public method signature or return type is changed. The only changed protocol is
private coordination between `SQLUpdateCompiler` and `UpdateQuery`.
