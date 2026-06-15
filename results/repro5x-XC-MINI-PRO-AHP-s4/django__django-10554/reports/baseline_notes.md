# Baseline notes — django__django-10554

## Issue

> Union queryset with ordering breaks on ordering with derived querysets

Given a combined queryset (`union()` / `intersection()` / `difference()`), deriving a
new queryset from it and ordering by a column that is **not part of the SELECT list**
fails. The most common way to hit this is to take a `union()`, restrict the columns
with `.values_list(...)` / `.values(...)`, and then order by a different field:

```python
union_qs = qs1.union(qs2)
union_qs.order_by('-pk').values_list('order', flat=True)   # 'pk' is not in the values list
union_qs.values_list('order', flat=True).order_by('-pk')
```

On the buggy code this raises
`django.db.utils.DatabaseError: ORDER BY term does not match any column in the result set.`
(and, on the version the reporter ran, surfaced from the database as
`ORDER BY position N is not in select list`).

## Root cause

`SQLCompiler.get_order_by()` (`django/db/models/sql/compiler.py`) handles ordering for
combined queries specially: because the parts of a compound (UNION/…) statement can't be
referenced by qualified column names, each ORDER BY term is *relabeled* to the raw 1-based
position of the matching column in the SELECT list (`ORDER BY (4)`).

The relabeling loop walked `self.select` looking for the column the ORDER BY term refers
to. If it didn't find it, the `for … else` branch unconditionally raised
`DatabaseError('ORDER BY term does not match any column in the result set.')`.

That is correct when the SELECT columns are *aliased* (e.g. a `.values('a', b=F('x'))`
query): ordering by something outside the explicit projection genuinely can't be resolved.
But when the combined query selects plain columns without aliases (the normal
`values_list()` case), an ORDER BY column that simply isn't in the (reduced) projection
*can* be satisfied by adding it to the SELECT list — exactly what Django already does for
ordinary (non-combined) queries. The old code had no way to do this for combined queries,
so any ordering of a derived/restricted union by a non-selected column blew up.

A secondary gap in the same loop: when ordering by an `F()` expression whose name matches
an *aliased* select column, the `elif col_alias: continue` skipped that column, so the term
was never matched.

## Fix

Two small, targeted changes.

### 1. `django/db/models/sql/compiler.py` — `SQLCompiler.get_order_by()`

- Capture the *unresolved* source of the ORDER BY term: `expr_src = expr.get_source_expressions()[0]`.
- When deciding whether to skip an aliased select column, don't skip it if the ORDER BY
  term is an `F('name')` that matches that alias:
  `elif col_alias and not (isinstance(expr_src, F) and col_alias == expr_src.name): continue`.
- Replace the unconditional `else: raise …` with:
  - still raise when the (last seen) select column was aliased — preserves the existing
    contract tested by `test_order_raises_on_non_selected_column` (ordering a
    `.values(...)` union by a column outside the projection must raise);
  - otherwise add the ordering column to the selected columns
    (`self.query.add_select_col(src)`) and relabel the term to the new last position
    (`RawSQL('%d' % len(self.query.select))`).

`F` is now imported from `django.db.models.expressions`.

Because `add_select_col` also extends `values_select`, the column is propagated to every
combined query in `get_combinator_sql()` (which builds the parts' SELECT lists from
`self.query.values_select`), so all parts of the compound statement keep matching column
counts and the relabeled position is valid.

### 2. `django/db/models/sql/query.py` — `Query.add_select_col()`

New helper (placed next to `set_select`):

```python
def add_select_col(self, col):
    self.select += col,
    self.values_select += col.output_field.name,
```

## Why this does not corrupt a reused union queryset

The reported "re-evaluating the original queryset breaks" symptom is the shared-state
problem: derived querysets (`order_by()`, `values_list()`) clone the *outer* query but
share the tuple of `combined_queries`. Compilation must therefore not mutate those shared
inner query objects. `get_combinator_sql()` already clones each combined query before
calling `set_values()` on it (the `compiler.query = compiler.query.clone()` line), so the
shared inner queries are never mutated by a derived queryset's evaluation.

`add_select_col()` mutates only `self.query` — and for a derived queryset that `self.query`
is the derived clone (created by `order_by()`/`values_list()` via `_chain()`), never the
original union's query or its shared `combined_queries`. So evaluating a derived,
non-selected-column ordering leaves the original `union_qs` intact and reusable.

## Files changed

- `django/db/models/sql/compiler.py` — import `F`; rework the combinator branch of
  `get_order_by()` to add a missing ORDER BY column to the select instead of always
  raising, plus the `F`-alias match.
- `django/db/models/sql/query.py` — add `Query.add_select_col()`.

## Assumptions / alternatives considered and rejected

- **"Clone the query/queryset before changing it" (the reporter's hypothesis).** The
  shared-combined-query mutation that the hypothesis targets is already prevented by the
  existing `clone()` in `get_combinator_sql()`; with the simple reproduction (clearing the
  order, then `values_list('pk')`) the derived evaluation no longer corrupts the union on
  current code. The remaining, still-broken behavior is ordering a *restricted* combined
  query by a column not in its projection, which is an additive-select problem, not a
  copy problem. Hence the fix is in `get_order_by()`/`add_select_col`, matching how
  ordinary querysets already pull non-selected ordering columns into the SELECT.
- **Always raising (status quo) but documenting the limitation.** Rejected — it leaves the
  feature broken; the whole point of the ticket is to make ordering derived combined
  querysets work.
- **Adding the column only to `select` (not `values_select`).** Rejected — the combined
  parts' SELECT lists are built from `values_select` in `get_combinator_sql()`, so the
  parts would emit fewer columns than the relabeled position expects, reproducing the
  `ORDER BY position N is not in select list` error.
- **Touching the `Values*` iterables to hide the appended column.** Not needed for the
  fix: with `flat=True` the single value is taken positionally, and `values()` already
  limits the yielded keys to the originally requested names. Kept the change minimal and
  localized to the SQL layer.
