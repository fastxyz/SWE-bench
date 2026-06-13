# Baseline notes — django__django-15128

## Issue

`Query.change_aliases` raises `AssertionError` when OR-ing (or AND-ing) two
querysets whose `WHERE` clause contains a queryset subquery, e.g.

```python
qs1 = qux.foos.all()
qs2 = Foo.objects.filter(
    Q(bars__baz__in=qux.bazes.all()) | Q(other_bars__baz__in=qux.bazes.all())
)
qs1 | qs2   # AssertionError in Query.change_aliases, change_map = {'T4': 'T5', 'T5': 'T6'}
```

The failing assertion is the first line of `change_aliases`:
`assert set(change_map).isdisjoint(change_map.values())`.

## Root cause

`Query` generates table aliases from a per-query `alias_prefix` (the class
default is `'T'`). Both operands of an OR/AND therefore use the *same* prefix.

`Query.combine()` merges `rhs` into `self` (the lhs, which has already been
cloned by `QuerySet.__or__`/`__and__`). For every `rhs` join it calls
`self.join()`, which mints a brand-new alias for `self` using
`self.alias_prefix` and `len(self.alias_map) + 1` (see `Query.table_alias`).
When `self` already contains the same tables, those freshly-minted aliases are
numbered (`T4`, `T5`, …). Because `rhs` uses the same prefix, the new aliases
collide with `rhs` aliases that have **not been relabelled yet**. The resulting
`change_map` then has keys that are also values, e.g. `{T4: T5, T5: T6}` — `T5`
is both the new alias chosen for `rhs`'s `T4` and an existing `rhs` alias still
awaiting relabelling.

`combine()` itself relabels its `WHERE`/`SELECT` with single dictionary lookups,
which tolerate the overlap. But the `WHERE` clause contains the
`__in=<queryset>` subqueries. Relabelling a `Lookup` whose rhs is a `Query`
(`Expression.relabeled_clone` → `Query.relabeled_clone` → `Query.change_aliases`)
hands the whole `change_map` to the subquery's `change_aliases`, whose very
first line asserts that keys and values are disjoint — and fails. (The assertion
is correct: `change_aliases` renames the internal `alias_map`/`table_map`/
`alias_refcount` in a sequential loop, so an alias that is both a key and a value
would be renamed twice and produce a non one-to-one relabelling.)

This matches the maintainers' analysis in the public hints: the two queries
"share the same alias_prefix" and the fix is to "change the alias_prefix of the
rhs … so it doesn't conflict before proceeding with the creation of the
change_map", reusing `bump_prefix` with a parameter and keeping the shared
"initial" (base table) alias so it can still serve as the merge starting point.

## Changes (all in `django/db/models/sql/query.py`)

### 1. `Query.bump_prefix` — new `exclude` parameter
`bump_prefix` already contains all the logic to pick a fresh, non-colliding
prefix and relabel the query's aliases accordingly. It is now usable by
`combine` by accepting an `exclude` set of aliases that must **not** be
relabelled. `combine` passes the base table so the shared merge starting point
keeps its alias; all other aliases get the new prefix. The parameter defaults to
`None` (treated as empty), so the existing subquery caller
(`Query.resolve_expression`) is unaffected. The first positional parameter was
renamed `outer_query` → `other_query` to reflect that the merge target is not an
*outer* query; both existing callers pass it positionally, so this is safe.

### 2. `Query.combine` — bump the rhs prefix before building the change_map
When `self.alias_prefix == rhs.alias_prefix`, the rhs aliases are bumped to a
distinct prefix first. Consequences:
- `change_map` keys (rhs aliases, now e.g. `U…`) and values (aliases generated
  with `self.alias_prefix`, e.g. `T…`, or first-occurrence table names) become
  disjoint by construction, so the assertion holds everywhere the map flows,
  including into the subqueries.
- The **final** aliases of the combined query are unchanged from the
  (pre-bug-fix) intended output: the bumped rhs aliases are only intermediate
  keys and are mapped to `self`-prefixed values, so the generated SQL keeps the
  same alias scheme (the lhs aliases are never touched).

`combine` documents that `rhs` is not modified, so the bump is applied to a
`rhs.clone()`. Because `Query.clone()` only *shallow*-copies `table_map` (its
values are lists that `change_aliases` mutates **in place**), the clone's
`table_map` lists are copied explicitly; otherwise bumping the clone would
corrupt the original `rhs.table_map` and leave the caller's queryset internally
inconsistent (`table_map` out of sync with `alias_map`).

### 3. `Query.change_aliases` — documenting the assertion
Added a comment explaining why `change_map`'s keys and values must be disjoint
(an alias appearing as both would be relabelled twice). The reporter explicitly
asked for this clarification; the assertion itself is kept as a valid invariant
that the `combine` fix now upholds.

## Assumptions and rejected alternatives

- **Bump `rhs` (on a clone), not `self`.** `self` is always a fresh
  `_chain()`/clone in the only callers (`__or__`/`__and__`), so it is safe to
  mutate, and bumping it would also produce a disjoint map. It was rejected
  because relabelling `self` rewrites the *lhs* (output-dominant) aliases — e.g.
  a first-occurrence left join that currently renders without an explicit alias
  would gain one — changing generated SQL broadly. Bumping `rhs` keeps both the
  lhs aliases and the final combined aliases identical to the intended output.
- **Mutate `rhs` in place (no clone).** Rejected: `combine`'s contract says
  `rhs` is not modified, and an in-place bump would corrupt the caller's
  queryset (notably an inconsistent `table_map`). Cloning preserves the
  contract; the extra clone only happens on set operations, not in hot loops.
- **Make `change_aliases` tolerate intersecting change_maps** (apply renames in
  dependency order or via temporary aliases). Rejected as the primary fix: the
  maintainer guidance is to prevent the intersection at the source (`combine`),
  and the disjointness assertion is a useful invariant worth keeping. The fix
  instead guarantees the invariant and documents it.
- **Random / rotating alias prefixes** (suggested in the issue thread).
  Rejected for the reasons given there: random first letters cause
  non-deterministic failures, and naive rotation eventually collides with
  subquery aliases. `bump_prefix`'s existing Cartesian-product generation that
  avoids `subq_aliases` is reused instead.
- The fix is prefix-agnostic and applies to both OR and AND combinations
  (the bump happens before the connector-specific logic), since the same
  intersecting-`change_map` hazard exists for AND as well.
