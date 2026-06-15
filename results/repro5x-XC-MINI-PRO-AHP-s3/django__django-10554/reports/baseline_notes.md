# Baseline notes — django__django-10554

## Issue

Building an ordered combinator queryset and then deriving another queryset from it
corrupts the original:

```python
qs = (
    Dimension.objects.filter(pk__in=[10, 11])
    .union(Dimension.objects.filter(pk__in=[16, 17]))
    .order_by('order')
)
list(qs)                                   # works
qs.order_by().values_list('pk', flat=True) # derive + evaluate a new queryset — works
list(qs)                                   # now BREAKS:
# django.db.utils.ProgrammingError: ORDER BY position 4 is not in select list
#   ... id" IN (16, 17)) ORDER BY (4) ASC LIMIT ...
```

The public hint points straight at it: *"a bug caused by a `.query` attribute change
without performing a prior `copy()` of the query/queryset."*

## Root cause

`union()`/`intersection()`/`difference()` are implemented in
`QuerySet._combinator_query()` (`django/db/models/query.py`), which stores the operand
querysets' underlying `Query` objects in the outer query's `combined_queries` tuple:

```python
clone.query.combined_queries = (self.query,) + tuple(qs.query for qs in other_qs)
```

`Query.clone()` (`django/db/models/sql/query.py`) — the lightweight copy used by
*every* queryset-returning operation (`_chain()`/`_clone()`), by slicing, and by
`__repr__` — performed a **shallow** `obj.__dict__ = self.__dict__.copy()`. It
explicitly deep-copies the mutable bookkeeping structures (`alias_map`,
`alias_refcount`, `where`, `annotations`, …) but it did **not** copy
`combined_queries`. As a result the cloned `Query` shared not just the tuple but the
very same sub-`Query` objects with the original.

So the ordered union queryset and *every* queryset derived from it
(`qs.order_by()`, `.values_list('pk')`, the slice created by `__repr__`, …) all pointed
at the same `combined_queries[i]` objects.

The compound SQL is produced by `SQLCompiler.get_combinator_sql()`
(`django/db/models/sql/compiler.py`), which works directly off the outer query's
`combined_queries` and, to keep all members of the compound statement column-compatible,
mutates those sub-queries (most visibly by calling `set_values()` on them to project the
outer query's `values()`/`values_list()` selection). Because the sub-query objects were
shared, the outer combinator queryset and any queryset derived from it were operating on
the *same* `Query` instances. Compiling/deriving one of them is therefore able to alter
the column list emitted by the sub-queries of the *original* union.

The original union still computes its positional `ORDER BY` (`get_order_by()` relabels
combinator order-by terms to `ORDER BY <position>` using the outer query's full default
column list), so once the shared sub-queries emit a reduced column list the position no
longer exists — hence `ORDER BY position 4 is not in select list`.

The tell-tale detail that confirms the diagnosis is in the report itself: evaluating the
union *in place* (`[dim.id for dim in qs]`) keeps working, while *deriving a new queryset
and evaluating that* poisons the original. That is precisely the signature of shared,
un-copied mutable state reachable through more than one queryset — and it is exactly the
"`.query` attribute change without performing a prior `copy()`" called out in the hint.

## Fix

`django/db/models/sql/query.py`, `Query.clone()` — clone the combined sub-queries
instead of sharing them:

```python
# Clone attributes that can't use shallow copy.
obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
```

For ordinary (non-combinator) queries `combined_queries` is the empty tuple, so this is
a no-op and costs nothing; for combinator queries each derived queryset now owns
independent copies of its operands' queries. After cloning, an outer combinator query
and any queryset derived from it no longer share *any* mutable state
(`clone()` already deep-copies every other mutable attribute, and the remaining shared
attributes — `select`, `values_select`, `order_by`, … — are immutable tuples that are
reassigned, never mutated in place). Compilation-time adjustments to one queryset's
sub-queries can therefore no longer corrupt another.

This is a one-line, surgical change that matches the hint ("perform a `copy()` of the
query") and is placed alongside the existing "attributes that can't use shallow copy"
block. `Query.__deepcopy__()` delegates to `clone()`, so pickling/deepcopy paths inherit
the fix as well.

## Files changed

- `django/db/models/sql/query.py` — in `Query.clone()`, deep-copy `combined_queries`
  (`tuple(query.clone() for query in self.combined_queries)`) so combinator sub-queries
  are not shared between a queryset and its derivatives.

## Assumptions and alternatives considered

- **Interpretation of the (slightly mis-formatted) reproduction.** I read it as
  `A.union(B).order_by('order')` — i.e. the ordering is applied to the *outer* union.
  This is consistent with the title ("Union queryset with ordering…") and with the
  failing SQL showing a positional `ORDER BY (4)` at the compound (outer) level, which is
  only produced for `query.combinator` queries by `get_order_by()`.

- **Fixing `_combinator_query()` instead** (cloning the operand queries when the
  combinator is first built). Rejected: that only stops the union from sharing state
  with its *source* querysets. It does **not** help the reported case, because every
  queryset *derived* from the union would still share the (now-cloned-once) tuple via the
  shallow `clone()`. The leak is between the union and its derivatives, so the copy has to
  happen in `clone()`.

- **Removing the existing `compiler.query = compiler.query.clone()` workaround in
  `get_combinator_sql()`** (it becomes partially redundant once `clone()` copies
  `combined_queries`). Rejected to keep the change minimal and low-risk: leaving it in
  place is harmless (it just clones a sub-query that the cloning in `clone()` already made
  independent) and preserves the existing, tested behaviour of the `values()`/
  `values_list()` + combinator paths.

- **Guarding individual mutation sites in the compiler** (e.g. cloning before each
  in-place change). Rejected: it is brittle and would have to enumerate every present and
  future place that touches a combined sub-query. Making `clone()` produce genuinely
  independent queries fixes the entire class of "shared combined query" aliasing bugs at
  the source, consistent with how `clone()` already treats every other mutable attribute.

- **Performance.** `clone()` is hot, but `combined_queries` is empty for all
  non-combinator queries (the overwhelming majority), so the added work is a cheap empty
  comprehension; only combinator queries pay for the recursive clone, which is correct and
  bounded by the (finite) nesting depth of the compound query.
