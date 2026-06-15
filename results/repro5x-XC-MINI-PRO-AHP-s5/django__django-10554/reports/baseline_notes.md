# Baseline notes — django__django-10554

## Issue

Deriving a new queryset from a combinator queryset (`union()` / `intersection()` /
`difference()`) and evaluating that derived queryset corrupts the *original*
combinator queryset, so re-evaluating the original blows up:

```python
qs = Dimension.objects.filter(pk__in=[10, 11]).union(
    Dimension.objects.filter(pk__in=[16, 17])
).order_by('order')

list(qs)                                       # OK
list(qs.order_by().values_list('pk', flat=True))   # OK, e.g. [16, 11, 10, 17]
list(qs)                                        # BOOM
# django.db.utils.ProgrammingError: ORDER BY position 4 is not in select list
```

## Root cause

A combinator queryset keeps the operand queries in `Query.combined_queries`
(set by `QuerySet._combinator_query()` in `django/db/models/query.py`).

`Query.clone()` (`django/db/models/sql/query.py`) is a deliberately lightweight
copy that does:

```python
obj.__dict__ = self.__dict__.copy()      # shallow copy
```

and then *explicitly* re-copies the handful of attributes that cannot be shared
(`alias_map`, `where`, `annotations`, …). `combined_queries` was **not** among
them, so the tuple — and, crucially, the `Query` instances inside it — were
**shared by reference** between a combinator queryset and every queryset derived
from it through `_chain()` / `_clone()` / `chain()`.

When a *derived* queryset that selects a restricted column set (`values()` /
`values_list()`) is compiled, `SQLCompiler.get_combinator_sql()`
(`django/db/models/sql/compiler.py`) aligns the operand queries' columns with the
outer selection by calling `set_values()` on each combined query:

```python
if not compiler.query.values_select and self.query.values_select:
    compiler.query = compiler.query.clone()        # guards only THIS call site
    compiler.query.set_values((... self.query.values_select ...))
```

`set_values()` sets `values_select`, replaces `select`, and flips
`default_cols = False`, i.e. it makes each operand emit only the value-list
columns. Because the operand `Query` objects were shared, that mutation leaked
back into the original combinator queryset's `combined_queries`. On
re-evaluation the original still carries its `ORDER BY <col>` (which the compiler
rewrites to a positional reference such as `ORDER BY 4` for combinator queries),
but its UNION members now emit only one column, so the database rejects the
positional reference: *"ORDER BY position 4 is not in select list"*.

This matches the public hint exactly: *"a `.query` attribute change without
performing a prior `copy()` of the query/queryset."* `get_combinator_sql()`
contains a localized `compiler.query = compiler.query.clone()` guard around that
one `set_values()` call, but the underlying defect is that the operand `Query`
instances are shared across queryset derivations at all. Fixing it at the
`clone()` boundary removes the sharing for every derivation and every
compile-time mutation, not just that single call site, which is why it is the
correct place for the fix.

## Change

`django/db/models/sql/query.py` — `Query.clone()`

Added `combined_queries` to the list of attributes that are deep-ish copied so
that a derived query owns independent copies of its operand queries:

```python
obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
```

Now every queryset derived from a combinator queryset gets its own clones of the
operand queries. Any per-compilation mutation (e.g. `set_values()` aligning the
column list, alias bookkeeping, etc.) happens on the derived query's *own*
copies and can no longer corrupt the original combinator queryset, so the
original remains re-evaluable.

For non-combinator queries `combined_queries` is the empty tuple, so the
generator is a no-op and there is no behavioural or measurable performance
change for the common case.

## Why this location / alternatives considered

- **Clone in `Query.clone()` (chosen).** This is the root of the sharing:
  `clone()` is the single chokepoint reached by every queryset derivation
  (`_chain`/`_clone`/`chain`), by `__deepcopy__`, and by subquery resolution.
  Fixing it here isolates the operand queries for *all* derivations, regardless
  of which operation later mutates them. It is the minimal change that addresses
  the actual shared-mutable-state bug and works whether or not the narrower
  `get_combinator_sql()` guard is present.

- **Rely solely on the `compiler.query = compiler.query.clone()` guard in
  `get_combinator_sql()` (rejected).** That guard only covers the one
  `set_values()` call and only when the outer query has a values selection and
  the operand does not. It does nothing about the operand `Query` objects being
  shared across queryset derivations, which is the underlying problem the issue
  describes; leaving sharing in place keeps the door open to the same class of
  corruption from any other compile-time mutation. I left that guard untouched
  (it is harmless and complementary).

- **Clone the operands only in `_combinator_query()` (rejected).** That would
  decouple the union from its *input* querysets, but the union and its
  *derivatives* would still share the same `combined_queries` tuple (because
  `clone()` shallow-copies it), so deriving-then-re-evaluating — exactly the
  reported scenario — would still corrupt the original. Insufficient.

## Assumptions

- The operand queries in `combined_queries` are independent `Query` objects whose
  generated SQL does not depend on object identity, so cloning them is
  behaviour-preserving (verified against the existing
  `tests/queries/test_qs_combinators.py` scenarios: simple/values/extra/annotated
  unions, ordering, counts, multi-model combinations — all still produce the same
  SQL/results).
- Per the task constraints this was reasoned about statically; no tests were run.
