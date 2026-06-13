# Code review — V1 fix for django__django-15128

Scope reviewed: `django/db/models/sql/query.py` changes to `Query.combine`,
`Query.bump_prefix`, and `Query.change_aliases` (assertion comment).

Legend: ✔ = confirmed correct, ⚠ = improvement made in V2, ◑ = noted, no change.

---

## F1 — Correctness against the issue (✔)
The bug is the `assert set(change_map).isdisjoint(change_map.values())` in
`change_aliases`, reached when `combine` builds an intersecting `change_map`
(e.g. `{T4: T5, T5: T6}`) and propagates it through a queryset subquery in the
`where` clause (`Lookup.relabeled_clone` → `Query.relabeled_clone` →
`change_aliases`). V1 bumps the rhs aliases to a distinct prefix before building
`change_map`. I traced a concrete crashing scenario:

- `self.alias_map = {app_foo, app_qux}` (lhs has one join to a table rhs doesn't
  use), `rhs.alias_map = {app_foo, app_bar, app_baz, T4, T5}`.
- Without the fix: `combine` mints `T5`, `T6` for rhs's `T4`, `T5` →
  `change_map = {T4: T5, T5: T6}` → keys ∩ values = {T5} → assertion fails.
- With the fix: rhs is bumped to `{app_foo, U1, U2, U3, U4}`, so
  `change_map = {U1: app_bar, U2: app_baz, U3: T5, U4: T6}` → keys (`U…`) and
  values (`app_…`/`T…`) are disjoint → assertion holds in the subquery too.

Conclusion: V1 fixes the root cause described in PROBLEM.md.

## F2 — The literal minimal repro does not crash on this version (◑)
Tracing the exact snippet (`qs1 = qux.foos.all()`), `qs1` is *base-only*
(`filter(qux=...)` compares the FK column directly, no join), so combine mints
`app_bar/app_baz/T4/T5` whose names equal rhs's own aliases → all
`alias == new_alias` → `change_map = {}` → no intersection, no crash. The crash
requires the lhs to already contain a join to a table **not** shared with rhs
(so the alias counter is inflated and rhs's numbered aliases collide). This is a
note about how a regression test must be shaped (the lhs needs a join); it does
not require a code change — V1 targets the documented root cause (shared
`alias_prefix`) and handles the general crashing case (F1).

## F3 — Output is preserved for both crashing and non-crashing inputs (✔)
The bumped rhs prefix is only an *intermediate* key in `change_map`; values are
still minted with `self.alias_prefix` (unchanged) or table names, so the final
combined query's aliases are identical to what the pre-fix code intended. I
verified equivalence for: simple single-table OR (no aliases either way), lhs
with joins reused by rhs (all reused, empty effective relabelling), and the
crashing case (final `alias_map` identical, `where`/`select` references mapped
to the same final aliases). Subqueries here are non-correlated (empty
`external_aliases`), so their `change_aliases` is a no-op apart from the
assertion — relabelling them twice (orig→`U`→final) is a round-trip. No SQL
change for inputs that already worked.

## F4 — "rhs is not modified" contract (✔, see F5)
`combine`'s docstring promises rhs is not modified. V1 operates on `rhs.clone()`,
so the original rhs object is preserved. I enumerated everything
`change_aliases` touches on the (cloned) rhs:
- `where`: clone owns an independent tree (`where.clone()`); `relabel_aliases`
  replaces `Lookup` children with new `relabeled_clone`s and only mutates
  sub-`WhereNode`s, which are themselves deep-cloned. Original untouched.
- `select`, `group_by`, `annotations`, `external_aliases`: **reassigned** to new
  objects; originals untouched.
- `alias_map`, `alias_refcount`: the clone owns fresh dicts; values
  (`Join`/`BaseTable`) are never mutated (`relabeled_clone` returns new joins).
- `table_map`: **the only shared-mutable hazard** — see F5.

## F5 — `clone()` shallow-copies `table_map`; its list values are shared (✔)
`Query.clone()` does `obj.table_map = self.table_map.copy()` (line 308): a new
dict but the *list* values are shared with the original. `change_aliases`
mutates those lists in place (`table_aliases[pos] = new_alias`, line 897). So a
naive `rhs.clone()` + bump would corrupt the *original* rhs's `table_map`
(leaving it inconsistent with its `alias_map`, which would mis-alias the
caller's queryset if reused/filtered later). V1 explicitly copies the lists
(`{table: aliases.copy() ...}`), which is necessary and correct. `table_map`
values are always lists (lines 170, 787), so `list.copy()` is valid.

## F6 — Excluding the base table from the bump (✔)
`combine` relies on lhs and rhs sharing the same base-table alias (rhs's base is
skipped via `list(rhs.alias_map)[1:]`, and rhs's `where` references to the base
must match lhs's base). If the bump relabelled the base (`app_foo → U0`), rhs's
base references would no longer be in `change_map` and would dangle. V1 passes
`exclude={rhs.base_table}`, keeping the base; non-base joins still reference the
base correctly because `app_foo` is not in the bump's `change_map`
(`relabeled_clone` leaves the parent alias unchanged). Verified correct and
necessary.

## F7 — New-prefix selection vs. lhs subquery prefixes (✔)
`bump_prefix` picks the next prefix not in *rhs*'s `subq_aliases`, so it avoids
rhs's own nested-subquery prefixes. It does not consult lhs's `subq_aliases`,
but that is fine: rhs's bumped top-level aliases are intermediate keys that are
mapped to lhs-prefixed values, so they never appear in the final query and
cannot clash with lhs subquery prefixes. The disjointness needed for the
assertion only requires `rhs_new_prefix != self.alias_prefix`, which
`bump_prefix` guarantees (it yields a letter strictly after the current one).

## F8 — AND connector also covered (✔)
For `&`, `reuse = set()`, so rhs joins always create new aliases — the same
`{T4: T5, …}` hazard exists. The bump runs before the connector-specific logic,
so AND combinations are fixed identically. No regression for AND.

## F9 — Unnecessary clone for base-only rhs (⚠ improved in V2)
V1 clones rhs on *every* prefix-matching combine, i.e. effectively every `|`/`&`
(both operands default to prefix `'T'`), even when rhs has no joins to relabel.
`Model.objects.filter(a=1) | Model.objects.filter(b=2)` (both base-only, a very
common pattern) would clone+copy `table_map`+bump for nothing: with
`len(rhs.alias_map) <= 1`, `rhs_tables` is empty, the relabel loop never runs,
and no intersection is possible. V2 adds an `and len(rhs.alias_map) > 1` guard
to skip the clone in that case. The guard is behaviourally transparent (it only
gates an internal clone; `self.alias_prefix`, the combined SQL, and rhs all stay
identical either way), so it carries no test risk.

## F10 — `bump_prefix(exclude=...)` default and filtering (✔)
`exclude=None` is normalised to `{}` and the comprehension keeps every alias
when nothing is excluded, so the two existing positional callers
(`resolve_expression` line ~1056, `split_exclude` line ~1817) are unaffected and
still relabel all aliases (including the base) as before. No regression.

## F11 — Docstring clarity for `exclude` (⚠ improved in V2)
The V1 phrasing "To prevent changing aliases use the exclude parameter" is
ambiguous (could read as disabling all relabelling). V2 clarifies: "Aliases in
the optional exclude set are not relabelled."

## F12 — Parameter rename `outer_query` → `other_query` (◑ kept)
`bump_prefix` is now also called from `combine`, where the argument is the merge
target (a sibling), not an enclosing/outer query, so `other_query` is more
accurate and reads correctly for both the subquery and combine call sites. Both
existing callers pass it positionally, so the rename is safe; an internal Query
method is not called by keyword from outside. Kept.

## F13 — Assertion comment in `change_aliases` (✔)
The added comment accurately explains why keys/values must be disjoint (an alias
that is both would be relabelled twice in the sequential rename loop). The
assertion is kept as a valid invariant that the combine fix now upholds — the
PROBLEM.md author explicitly requested this explanation.

## F14 — Surrounding interactions (✔)
- `joinpromoter`: `relabeled_clone` preserves `join_type`, so INNER/LOUTER votes
  and `update_join_types` behave the same after the bump.
- Unused-alias detection (`if not rhs.alias_refcount[alias]`): `change_aliases`
  copies refcounts to the new alias keys, so the U-prefixed keys carry the right
  counts.
- `self.get_initial_alias()` (lhs) runs after the bump and is independent of it
  (bump touches rhs only); ordering is fine.
- `self.subq_aliases |= rhs.subq_aliases` (post-loop) still runs for the
  non-bumped path; for the bumped path it is redundant (bump already unioned),
  but harmless.

## F15 — Approach choice vs. relaxing the assertion (◑)
An alternative is to make `change_aliases` tolerant of intersecting maps. It was
rejected as the primary fix: in the failing flow the conflicting aliases never
reach `change_aliases` step 2 on a query that actually contains them (top-level
relabelling uses single-dict-lookup `relabel_aliases`; subqueries don't contain
the aliases), so only the assertion fires — but the assertion is a genuine
invariant worth keeping, and the maintainer guidance (per PROBLEM.md hints) is to
prevent the intersection at the source. V1's approach keeps the invariant intact.
