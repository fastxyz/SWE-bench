# Baseline notes — django__django-10554

## Issue

> Union queryset with ordering breaks on ordering with derived querysets

Reproduction (paraphrased from `benchmark/PROBLEM.md`):

```python
qs = Dimension.objects.filter(pk__in=[10, 11]).union(
    Dimension.objects.filter(pk__in=[16, 17])
).order_by('order')

list(qs)                                       # works the first time
list(qs.order_by().values_list('pk', flat=True))   # works (a *derived* queryset)
list(qs)                                       # BREAKS on re-evaluation
# django.db.utils.ProgrammingError: ORDER BY position 4 is not in select list
#   ... IN (16, 17)) ORDER BY (4) ASC LIMIT ...
```

The public hint: *"Looks like a bug caused by a `.query` attribute change without
performing a prior `copy()` of the query/queryset."*

## Root cause

A combinator queryset (`union()` / `intersection()` / `difference()`) keeps the
queries it combines in `Query.combined_queries`
(`django/db/models/query.py:_combinator_query`).

`Query.clone()` (`django/db/models/sql/query.py`) is a deliberately lightweight
copy: it does `obj.__dict__ = self.__dict__.copy()` and then explicitly deep-copies
only a hand-picked set of mutable attributes (alias maps, `where`, `annotations`,
masks, …). `combined_queries` was **not** in that list, so the tuple *and the
`Query` instances inside it* were shared by reference between a query and every
clone derived from it. Since every queryset-returning operation (`order_by()`,
`values_list()`, slicing, `_chain()`, …) goes through `clone()`, all derivatives of
a union shared the same underlying combined `Query` objects.

During SQL generation, `SQLCompiler.get_combinator_sql()`
(`django/db/models/sql/compiler.py`) calls `set_values()` on each combined query so
that every branch of the set operation selects the same column list. That call
mutates the combined `Query` **in place** (it resets `select`, `values_select`,
`default_cols`, masks, …).

Putting it together:

1. Evaluating the *derived* `qs.order_by().values_list('pk')` runs
   `get_combinator_sql()`, which reduces each combined query to a single column
   (`pk`) via `set_values()`.
2. Because the combined `Query` objects are shared with the original `qs`, that
   reduction is now visible to `qs` as well.
3. The compiler rewrites a combinator query's `ORDER BY` terms to *raw column
   positions* (`get_order_by()` does
   `resolved.set_source_expressions([RawSQL('%d' % (idx + 1), ())])`), with the
   position computed from the union's own full select list (`order` → position 4).
4. Re-evaluating `qs` therefore emits `... ORDER BY 4`, but the now-mutated combined
   queries only emit one column, so the database rejects it:
   *"ORDER BY position 4 is not in select list"*.

This is exactly the "`.query` change without a prior copy" described in the hint:
the combined queries are mutated, and they were never copied, so the mutation leaks
across querysets.

## Fix

`django/db/models/sql/query.py` — `Query.clone()`

Clone the combined queries when copying a combinator query so each clone owns an
independent set of `Query` objects:

```python
if self.combinator:
    obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
```

This is placed alongside the other "attributes that can't use shallow copy" in
`clone()`. The guard `if self.combinator:` keeps it a no-op for ordinary
(non-combinator) queries — for those `combined_queries` is the empty tuple — and it
naturally recurses for nested set operations (e.g. a `difference()` whose operand is
an `intersection()`), because `query.clone()` on a combinator operand clones *its*
combined queries too.

With the fix, the derived `values_list('pk')` queryset operates on its own copies of
the combined queries; reducing them to a single column no longer touches the combined
queries backing the original union, so re-evaluating the union still emits the full
column list and `ORDER BY 4` remains valid.

### Files changed

- `repo/django/db/models/sql/query.py` — `Query.clone()` now deep-copies
  `combined_queries` for combinator queries. (Single, targeted change.)

## Assumptions and alternatives considered

- **Alternative A — clone only at the mutation site in `get_combinator_sql()`**
  (ensure `compiler.query = compiler.query.clone()` before `set_values()`).
  This guards the one currently-known in-place mutation, but leaves
  `combined_queries` shared everywhere else, so any other in-place mutation of a
  combined query during compilation/derivation could still leak across querysets.
  Cloning at `Query.clone()` is the root-level fix and is the more direct reading of
  the hint ("copy the query/queryset"), so it was preferred. (The conditional
  clone-at-mutation-site approach matches the discussion note in the issue that
  "we've not hit the right strategy yet".)

- **Alternative B — clone the source queries in `_combinator_query()`** when
  building `combined_queries`. This isolates a union from the source querysets it
  was built from, but it does **not** isolate sibling derived querysets from each
  other: they would still share the union's `combined_queries` through the shallow
  `clone()`. It therefore does not fix the re-evaluation crash on its own, and was
  rejected.

- The reproduction in the ticket is on PostgreSQL (which validates `ORDER BY <pos>`
  eagerly). The fix is backend-agnostic: it removes shared mutable state, so the
  combined queries can no longer be silently reduced behind the original union,
  regardless of how/when a particular backend surfaces the resulting mismatch.

- I did not modify any test files (per the task constraints) and made no unrelated
  refactors.
