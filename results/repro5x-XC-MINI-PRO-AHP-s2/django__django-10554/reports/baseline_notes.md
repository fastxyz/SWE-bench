# Baseline notes — django__django-10554

## Issue

> Union queryset with ordering breaks on ordering with derived querysets

Given a combined queryset (`union()` / `intersection()` / `difference()`), deriving a
new queryset from it and evaluating that derived queryset corrupts the *original*
combined queryset. A subsequent re-evaluation of the original then crashes, e.g.:

```python
qs = Dimension.objects.filter(pk__in=[10, 11]).union(
    Dimension.objects.filter(pk__in=[16, 17])
).order_by('order')

list(qs.order_by().values_list('pk', flat=True))   # derive + evaluate -> OK
list(qs)                                            # re-evaluate original -> CRASH
# django.db.utils.ProgrammingError: ORDER BY position 4 is not in select list
```

The reporter noted that *evaluating `qs` first* (so it caches its result) hides the
problem, which is the tell-tale sign of **shared mutable query state** being modified
behind the back of the original queryset, only surfacing when the original is
re-compiled. The public hint says it plainly:

> Looks like a bug caused by a `.query` attribute change without performing a prior
> `copy()` of the query/queryset.

## Root cause

`django/db/models/sql/query.py::Query.clone()` is the lightweight copy used by every
queryset-cloning operation (`_chain` → `_clone` → `Query.chain` → `Query.clone`). It
shallow-copies `self.__dict__` and then **explicitly deep-copies every piece of mutable
per-query state** that can't be shared safely (`where`, `annotations`, `alias_map`,
`alias_refcount`, `external_aliases`, `table_map`, `extra`, the select masks, etc.).

The one mutable structure it does **not** copy is `combined_queries` — the tuple of the
actual inner `Query` objects that were combined (set in `QuerySet._combinator_query`,
`query.py:934`):

```python
clone.query.combined_queries = (self.query,) + tuple(qs.query for qs in other_qs)
```

Every other attribute left out of `clone()`'s explicit copy list is an *immutable* tuple
(`select`, `order_by`, `values_select`, `group_by`, `deferred_loading`, …) which the
mutating `Query` methods *reassign* rather than mutate in place, so sharing those is
harmless. `combined_queries`, by contrast, holds **live, mutable `Query` objects**, and
those objects are mutated during query generation/usage of a combined query. The clearest
example is in `SQLCompiler.get_combinator_sql` (`compiler.py:428`), where the columns of
each combined query are set to match the outer query's `values()`/`values_list()` column
list.

Because `clone()` shares the same `combined_queries` (and therefore the same inner `Query`
instances) between the original union queryset and **every queryset derived from it**, a
mutation performed while compiling/using one derived queryset leaks back into the original
and into sibling clones. After such a leak the inner queries select fewer columns than the
original's outer query expects, so re-compiling the original emits `ORDER BY <position>`
referring to a column index that no longer exists in the (now shorter) select list —
hence `ORDER BY position 4 is not in select list`.

Since `combined_queries` is the *only* shared mutable object state that survives a
`clone()`, it is necessarily the channel through which a derived queryset can corrupt the
original — which is exactly the "`.query` change without a prior `copy()`" the hint
describes.

## Fix

`django/db/models/sql/query.py` — in `Query.clone()`, deep-copy `combined_queries` so that
each clone (and therefore each derived queryset) gets its own independent copies of the
combined queries:

```python
# Combined queries hold references to mutable Query objects. Cloning
# them here ensures that operations performed on a clone (e.g. setting
# the select columns for values()/values_list() at compile time) don't
# leak back into the original query and any other clones sharing the
# same combined queries.
if self.combined_queries:
    obj.combined_queries = tuple(
        query.clone() for query in self.combined_queries
    )
```

This is the minimal, targeted change. For non-combined queries `self.combined_queries` is
the empty tuple, so the guard makes the change a no-op on the overwhelmingly common path
(no extra work / allocations). For combined queries each inner `Query` is cloned, and the
clone recurses naturally, so nested combinators (a union of unions, as in
`test_qs_with_subcompound_qs`) are isolated too.

### Why the fix belongs in `clone()` (and not in `_combinator_query`)

The corruption flows from a *derived* queryset back to the *original*. The original and
its derivatives come to share `combined_queries` precisely because `clone()` copies the
tuple by reference. Cloning the inner queries only at union-creation time
(`_combinator_query`) would make the union independent of the original `inner1`/`inner2`
querysets, but the union and all of *its* clones would still share one set of inner
`Query` objects — so a derived queryset could still corrupt the original. Fixing it in
`clone()` severs the sharing for every derivation, which is the relationship the bug is
about.

## Files changed

- `django/db/models/sql/query.py` — `Query.clone()` now clones `combined_queries`
  (5 added lines plus a comment). No other behavior is altered.

## Assumptions & alternatives considered

- **Interpretation of the (mangled) reproduction.** The parentheses in `PROBLEM.md` are
  unbalanced; I read it as `inner1.union(inner2).order_by('order')` (i.e. the `order_by`
  is on the *outer* combined query). This is corroborated by the error
  `ORDER BY (4) ...`: position-number relabeling of an `ORDER BY` term only happens for a
  combinator/compound query (`compiler.py:345`, `if self.query.combinator:`); a plain
  inner query would emit `ORDER BY "order"`, not `ORDER BY (4)`. The alternative reading
  (`order_by` on the inner query) was rejected for this reason.

- **Fixing it only in the compiler (`get_combinator_sql`).** `compiler.py:429` already
  clones an inner query before setting its values, which guards that one specific
  code path. I left it untouched: it is a localized mitigation of a single mutation site,
  whereas the underlying defect is that derived querysets share mutable inner `Query`
  objects at all. Adding ever more per-call clones in the compiler would be whack-a-mole;
  copying `combined_queries` at clone time fixes the root cause once, for every present
  and future code path that touches a combined query.

- **Cloning in `_combinator_query` instead.** Rejected — see "Why the fix belongs in
  `clone()`" above; it does not break the original↔derived sharing that the report is
  about.

- **Deep-copying via `__deepcopy__`.** `Query.__deepcopy__` already delegates to
  `clone()`, so the new copy is automatically picked up there (e.g. pickling) without a
  separate change.

- **Regression risk.** The change only adds copies; it never shares less-isolated state
  than before. Existing combinator tests (`tests/queries/test_qs_combinators.py`) build
  fresh combined querysets and/or reuse the same source queryset multiple times
  (`qs1.union(qs1)...`); with independent inner-query copies their results are unchanged.
  (Tests were not run — this environment has no execution.)
