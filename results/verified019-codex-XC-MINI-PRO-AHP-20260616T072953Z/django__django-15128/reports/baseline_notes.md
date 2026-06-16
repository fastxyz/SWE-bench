# Baseline Notes

## Root cause

`Query.combine()` builds a `change_map` while merging the right-hand query's
joins into the left-hand query. When both queries use the same `alias_prefix`,
new aliases allocated on the left-hand side can overlap aliases that still
exist on the right-hand side. In the reported case, an alias such as `T4` was
mapped to `T5` while `T5` was also an original right-hand alias that later
mapped to `T6`. That overlapping key/value set is unsafe for relabeling nested
query expressions and can trip `Query.change_aliases()`'s assertion.

## Files changed

`repo/django/db/models/sql/query.py`

- In `Query.combine()`, the right-hand query is cloned and prefix-bumped before
  join merging when both sides share the same alias prefix and the right-hand
  query has joins beyond the base alias. The initial alias is excluded from
  that relabeling because the combine algorithm relies on both queries starting
  from the same base table alias.
- The cloned right-hand query's `table_map` alias lists are copied before
  calling `bump_prefix()` so the documented "rhs is not modified" behavior is
  preserved despite `Query.clone()` using a lightweight shallow copy.
- `Query.bump_prefix()` now accepts an `exclude` set of aliases that must not
  be relabeled. It also validates that generated aliases do not collide with
  either aliases being relabeled or aliases excluded from relabeling before
  accepting a prefix.

## Assumptions and alternatives considered

- I assumed the initial alias is the only alias that must be preserved for
  `Query.combine()` because the method skips `list(rhs.alias_map)[0]` and treats
  that alias as the shared base table.
- I rejected changing `table_alias()` to skip aliases present in the right-hand
  query because that would alter alias allocation globally and duplicate logic
  that already exists in `bump_prefix()`.
- I rejected random or rotating alias prefixes because alias generation must
  remain deterministic and must continue to account for nested subquery prefixes.
- I did not add or modify tests because the benchmark instructions forbid test
  file changes and running code.
