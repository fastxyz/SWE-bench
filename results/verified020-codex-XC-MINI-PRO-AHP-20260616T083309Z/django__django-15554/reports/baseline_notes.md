# Baseline Notes

## Root cause

`Query.join()` reused existing joins by calling `Join.equals()`. For `Join`,
`equals()` intentionally ignores the `filtered_relation` part of the join
identity, so two `FilteredRelation` aliases for the same relation path were
treated as the same join even when their ON-clause conditions differed.

That caused the second filtered alias to reuse the first alias and never add
its own SQL JOIN. The generated query therefore only contained one filtered
join and any later references to the second alias were effectively attached to
the first filter.

## Changed files

`repo/django/db/models/sql/query.py`

- Restored separate join reuse behavior for normal query construction versus
  `FilteredRelation` condition resolution.
- Normal `Query.join()` calls now compare joins with `==`, which includes the
  `filtered_relation` in `Join.identity` and keeps differently filtered aliases
  distinct.
- While compiling a `FilteredRelation` condition, `build_filter()` and
  `setup_joins()` pass `reuse_with_filtered_relation=True` so the condition can
  still reuse only the known aliases in the filtered relation path and compare
  via `Join.equals()`, which deliberately ignores the filtered relation object
  for that internal resolution step.

## Assumptions

- The intended behavior is that separately named `FilteredRelation` annotations
  should produce separate joins when their filtered relation identity differs,
  including different aliases or conditions.
- The existing `Join.equals()` behavior remains necessary while resolving a
  filtered relation's own condition, because those condition lookups refer to
  the underlying relation name rather than the annotated filtered alias.
- The change should be limited to join reuse logic; no model, compiler, or
  public `FilteredRelation` API changes are needed.

## Alternatives considered and rejected

- Changing `Join.equals()` to include `filtered_relation` globally was rejected
  because it would also affect `FilteredRelation.as_sql()` condition
  resolution, where ignoring `filtered_relation` is needed to bind the
  condition to the join being compiled.
- Forcing every `FilteredRelation` join to create a new alias was rejected
  because it would bypass the existing reuse rules for the filtered relation's
  internal path and could introduce unnecessary joins.
- Adding or modifying tests was rejected because this benchmark explicitly
  forbids editing test files.

