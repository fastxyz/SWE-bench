# Baseline notes — django__django-10554

## Issue

Combining querysets with `union()` (or `intersection()`/`difference()`) and then
ordering the result works on first evaluation, but **deriving another queryset from
it and evaluating that derived queryset breaks re-evaluation of the original**:

```python
qs = Dimension.objects.filter(pk__in=[10, 11]).union(
    Dimension.objects.filter(pk__in=[16, 17])
).order_by('order')

list(qs)                                       # OK
list(qs.order_by().values_list('pk', flat=True))  # OK
list(qs)                                       # -> ProgrammingError:
#   ORDER BY position 4 is not in select list
#   ...id" IN (16, 17)) ORDER BY (4) ASC LIMIT ...
```

The public hint says: *"a bug caused by a `.query` attribute change without
performing a prior `copy()` of the query/queryset."*

## Root cause

A combinator queryset keeps the queries it has to combine in
`Query.combined_queries`. They are stored as plain references to the underlying
source queries in `QuerySet._combinator_query()`
(`django/db/models/query.py:934`):

```python
clone.query.combined_queries = (self.query,) + tuple(qs.query for qs in other_qs)
```

`Query.clone()` (`django/db/models/sql/query.py`) builds the copy with a *shallow*
copy of the instance dict:

```python
obj.__dict__ = self.__dict__.copy()
```

`combined_queries` is a tuple, so the shallow copy makes the clone share the **very
same inner `Query` objects** as the original. Every method that returns a new
queryset (`order_by()`, `values()`, `values_list()`, `filter()`, slicing for
`repr()`, …) goes through `clone()`, so the original combined queryset and *all*
querysets derived from it point at the identical inner `Query` instances.

The SQL compiler mutates those inner queries while building the combined SQL. In
`SQLCompiler.get_combinator_sql()` (`django/db/models/sql/compiler.py`), when the
outer query is a `values()`/`values_list()` query, the column list of every
combined query is rewritten so all parts of the `UNION` select the same columns
(`compiler.query.set_values(...)`). Because the inner queries are shared, that
column rewrite performed while evaluating a *derived* `values_list('pk')` queryset
reduces the inner queries to a single column. When the original combined queryset
is re-evaluated afterwards it still emits the position-based combinator ordering
(`ORDER BY (4)`, the 4th selected column) computed from its own full column list,
but the now-shared inner queries only select one column — hence
`ORDER BY position 4 is not in select list`.

In short: derived querysets leak mutations back into the inner queries of the
original combined queryset because `clone()` never copied `combined_queries`.

## Fix

`django/db/models/sql/query.py` — `Query.clone()`

After the existing "clone attributes that can't use shallow copy" block, deep-copy
the combined queries so a combinator query and every queryset cloned from it own
independent inner `Query` objects:

```python
if self.combined_queries:
    obj.combined_queries = tuple(
        query.clone() for query in self.combined_queries
    )
```

This is the minimal place that fixes the whole class of problem: it is the single
copy point through which every derived queryset is produced, so after the change a
derived queryset can never mutate (via column rewriting or anything else) the inner
queries that the original combined queryset still relies on. The guard keeps the
change free for the overwhelmingly common non-combinator case (`combined_queries`
is the empty tuple) and recurses naturally for nested combinators (each inner
`clone()` clones its own `combined_queries`).

No test files were modified.

## Assumptions

- The order-by in the reproduction is applied to the *outer* combined query
  (`A.union(B).order_by('order')`). This is confirmed by the failing SQL
  `... ORDER BY (4) ASC ...`: the position-based ordering form (`ORDER BY (N)`) is
  only produced for a query whose `combinator` is set, i.e. the union query, not an
  inner part. The wording of the report's snippet is ambiguous (an unbalanced
  parenthesis), but the traceback removes the ambiguity.
- `combined_queries` is only ever populated for combinator querysets and is the
  empty tuple otherwise (set in `Query.__init__`), so guarding on its truthiness is
  equivalent to guarding on `self.combinator` while being explicit about what is
  being copied.
- Cloning the inner queries does not break the compiler: `get_combinator_sql()`
  rebuilds fresh compilers from `combined_queries` on every evaluation and relies
  on their *contents*, not their object identity, so independent copies behave
  identically.

## Alternatives considered and rejected

- **Clone the queries in `QuerySet._combinator_query()`** when first storing them
  (`combined_queries = tuple(q.query.clone() ...)`). This is the most literal
  reading of the hint and decouples the union from its *source* querysets, but it
  does not help the reported symptom: `clone()` would still shallow-copy the
  snapshot tuple, so the original combined queryset and its *derived* querysets
  would keep sharing those snapshots. The bug is specifically about derived
  querysets, which only `clone()` mediates. Source querysets are already immutable
  (every operation clones), so cloning at store time is unnecessary on its own.
- **Clone the compiler's query for every combined part in
  `get_combinator_sql()` (not just when applying `set_values`).** The compiler
  already clones the inner query before `set_values()` for the `values()` path, but
  relying on the compiler to defensively copy is a band-aid: it only protects the
  specific code paths that remember to do it, and leaves the shared-state root cause
  in place. Cloning once in `Query.clone()` fixes every path uniformly and matches
  the documented "missing copy when the query is copied" diagnosis.
- **Relabel/clone `combined_queries` in `change_aliases()`/`bump_prefix()`** — this
  concerns a different problem (alias collisions when a combinator queryset is used
  as a subquery) and is orthogonal to the re-evaluation corruption reported here, so
  it was left out to keep the change targeted.
