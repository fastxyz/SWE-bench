# Code review — V1 fix for django__django-10554

V1 change under review (`repo/django/db/models/sql/query.py`, `Query.clone()`):

```python
if self.combinator:
    obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
```

Reviewed against: the reproduction in `benchmark/PROBLEM.md`, the surrounding
`Query`/`QuerySet` cloning machinery, `SQLCompiler.get_combinator_sql()` /
`get_order_by()`, and the combinator tests in
`repo/tests/queries/test_qs_combinators.py`. No code was executed; behaviour is
reasoned about.

---

## F1 — Correctness vs. the reported issue (CONFIRMED)

Root cause: `Query.clone()` does a shallow `obj.__dict__ = self.__dict__.copy()` and
then deep-copies only an explicit allow‑list of mutable attributes.
`combined_queries` was not on that list, so the tuple **and the `Query` objects
inside it** are shared by reference between a combinator query and every queryset
derived from it (every queryset op goes through `clone()`/`chain()`).

During compilation, `SQLCompiler.get_combinator_sql()` calls `set_values()` on each
combined query to align all branches to one column list. The compiler also rewrites
a combinator query's `ORDER BY` terms to raw positions
(`get_order_by()`: `resolved.set_source_expressions([RawSQL('%d' % (idx + 1), ())])`).
When a derived queryset (`qs.order_by().values_list('pk')`) reduces the combined
queries to one column and those `Query` objects are shared, the original union later
emits one column while still ordering by `ORDER BY 4` → *"ORDER BY position 4 is not
in select list"*.

V1 gives each clone independent combined queries, so the reduction performed while
evaluating the derived queryset cannot reach the original union → re-evaluation emits
the full column list and `ORDER BY 4` is valid. The fix targets the exact mechanism
the public hint describes ("a `.query` change without performing a prior `copy()`").
**Correct.**

## F2 — Necessity & interaction with `get_combinator_sql` clone (KEY)

`get_combinator_sql()` (compiler.py:428–434) already clones the combined query
before `set_values()`:

```python
if not compiler.query.values_select and self.query.values_select:
    compiler.query = compiler.query.clone()
    compiler.query.set_values((...))
```

That line guards the **single** `set_values()` call site. V1 isolates combined
queries at the **root** (`clone()` itself), which guarantees no derived queryset can
mutate the original's combined queries through *any* path, not just that one. I
traced V1 in both configurations:

- **Without** the line-429 clone (`set_values` applied directly): with V1, a derived
  queryset already owns independent combined clones, so the direct mutation hits only
  those clones; the original union's combined queries stay full → re-eval valid.
- **With** the line-429 clone: V1's clones are cloned again at line 429 — a harmless
  double copy.

So V1 is **self-sufficient** (resolves the bug even if the line-429 clone were absent)
and **complementary** to the existing guard. The minimal possible fix would be the
line-429 clone alone, but that only covers `set_values`; V1 is the broader,
root-level "copy the query" fix the issue calls for, and is robust against any future
in-place mutation of a combined query during compilation. Keeping V1 is justified.

## F3 — Edge case: nested set operations (HANDLED)

For a combinator whose operand is itself a combinator (e.g.
`Number.objects.difference(Number.objects.intersection(...))`,
`test_qs_with_subcompound_qs`), V1's `query.clone()` recurses: the inner clone again
hits `if self.combinator:` and clones its own `combined_queries`. Nested branches are
isolated correctly.

## F4 — Guard condition (ACCEPTABLE)

`combinator` and `combined_queries` are always set together in
`QuerySet._combinator_query()`; `combinator` is `None`/`combined_queries` is `()` for
ordinary queries. `if self.combinator:` is therefore True exactly for set-operation
queries and skips the work (and the empty-tuple build) otherwise. An equivalent
`if self.combined_queries:` would be marginally more defensive against an impossible
"combined set but combinator unset" state; kept `if self.combinator:` as the
semantic, conventional check. No correctness impact.

## F5 — Performance (ACCEPTED TRADE-OFF)

V1 clones every combined branch on every `clone()` of a combinator query (recursively
for nesting): O(branches) extra copies per queryset operation. This mirrors how
`clone()` already deep-copies other shared mutable state (alias maps, `where`,
`annotations`, …) and there is no cheaper way to guarantee isolation. Not a
correctness concern; acceptable.

## F6 — Regression: identity reliance (NONE)

Searched `repo/django` and `repo/tests` for `combined_queries`: only
`_combinator_query()` (writes) and `get_combinator_sql()` (reads) use it, and nothing
depends on the *identity* of the contained `Query` objects. Cloning them is
transparent.

## F7 — Regression: annotations / `OuterRef` / `Exists` branches (NONE)

Cloning a branch goes through `Query.clone()`, which copies the `annotations` dict but
shares the annotation **expression** objects — exactly what every other `clone()` call
already does. Compilation does not mutate expression objects (`resolve_expression()`
returns copies), so annotated/`Exists(OuterRef(...))` branches
(`test_union_with_values_list_on_annotated_and_unannotated`,
`test_union_with_two_annotated_values_list`) produce the same SQL as before.

## F8 — Regression: count/aggregation and deepcopy (NONE / IMPROVEMENT)

`Query.get_aggregation()`/`get_count()` do `inner_query = self.clone()` for combinator
queries and then mutate `inner_query` (the *outer* query: `default_cols`, `select`),
never the branches. With V1, `inner_query` gets its own branch clones with identical
columns, so the generated `SELECT COUNT(*) FROM (<compound>)` SQL is unchanged
(`test_count_union`, `test_count_difference`, `test_count_intersection`).
`Query.__deepcopy__()` delegates to `clone()`, so deepcopying a compound query now
also isolates its branches — a strict improvement over the previous shared state.

## F9 — Comment accuracy (FIXED)

The V1 comment originally asserted the combined queries "are mutated in place … by
set_values()". With the line-429 clone present, `set_values()` runs on a clone, so the
statement over-claimed a specific mutation that is guarded elsewhere. Reworded to
explain the general rationale (combined queries are mutable state that gets aligned via
`set_values()` during compilation and therefore must not be shared between a query and
its clones) without asserting the shared objects are definitely mutated.

## F10 — Pre-existing, out-of-scope issue (NOTED, NOT FIXED)

`get_combinator_sql()`'s condition `if not compiler.query.values_select and
self.query.values_select` does **not** re-align a branch that already carries its own
(different) `values_select`, which can produce a column mismatch when an *already
values-selected* union is re-projected. This is a separate concern from #10554 (whose
reproduction uses unvalued branches), and the task requires a minimal, targeted change,
so it is recorded here but intentionally left untouched.

## F11 — Error handling (NO NEW PATHS)

V1 adds no new failure modes: `query.clone()` is the same routine already invoked
throughout the ORM and does not raise for valid `Query` instances; the generator
expression cannot fail for a tuple of `Query` objects. Nothing to handle.

---

### Verdict

V1 is correct, self-sufficient, and free of regressions (F1, F2, F6–F8, F11). It is
kept, with only a comment clarification (F9). Performance (F5), the guard choice (F4),
nesting (F3), and a separate out-of-scope bug (F10) are documented but require no code
change.
