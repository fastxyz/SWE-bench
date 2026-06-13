# SPEC.md — formal specification of the django__django-15957 fix

Human-readable companion to `fvk/mini-orm.k` and `fvk/mini-orm-spec.k`. Written in
**intent-spec mode**: the contract captures the *intended* behaviour inferred from
`benchmark/PROBLEM.md`, the issue discussion, and the names/comments; the V1 code is
checked against it. Default is **partial correctness** (correct *if* the query is
evaluated; termination of the SQL is the database's concern, not modelled).

Scope: the three functions V1 touches.

---

## Intent (from PROBLEM.md + ticket discussion)

> `Prefetch(lookup, queryset=qs[low:high], to_attr=...)` should prefetch, **for each
> parent instance**, the slice `[low:high]` of that parent's related objects (in the
> queryset's order), using a **single** efficient query — not load every related row
> and slice in Python.

The ticket explicitly points at the mechanism: a *top-N-per-group* query via
`RowNumber()/Rank()` partitioned by the relation, made possible by filtering against
window functions.

---

## F1 — `_filter_prefetch_queryset(queryset, field_name, instances)`

`django/db/models/fields/related_descriptors.py`. The new helper. Multi-valued
prefetch descriptors call it instead of `queryset.filter(**{field+"__in": instances})`.

### Precondition (assumed; partly enforced upstream)
- `queryset` is a model queryset (not `values()/values_list()/raw()` — enforced by
  `Prefetch.__init__`).
- `field_name` is the relation field used to match related rows to parents
  (`self.field.name` for reverse-FK; `self.query_field_name` for m2m). The `__in`
  lookup and the window's `partition_by` use the **same** `field_name`.
- `instances` is a non-empty list of parent instances (`prefetch_one_level` only calls
  the descriptor when `obj_to_fetch` is non-empty).
- If `queryset.query.is_sliced`, then `0 <= low_mark` and
  `high_mark is None or low_mark <= high_mark`. **Guaranteed** by `Query.set_limits`,
  which clamps marks and never produces negatives (querysets reject negative indexing).

### Postcondition
Returns a queryset `R` such that, when evaluated, `R` yields **exactly**
`⋃_{p ∈ instances} relset(p)[low:high]` where `relset(p)` is the parent `p`'s related
rows in the queryset's effective order, and:
- **Not sliced** (`low_mark == 0 and high_mark is None`): `[low:high]` is the identity;
  `R` ≡ `queryset.filter(field_name__in=instances)` — i.e. V1 is behaviour-preserving
  for the overwhelmingly common non-sliced prefetch. (No window, no `clear_limits`.)
- **Sliced**: `R` keeps, per partition `field_name`, the rows whose 1-indexed
  `RowNumber()` (ordered by the queryset's ordering) lies in the half-open integer
  interval `(low_mark, high_mark]` (or `(low_mark, ∞)` when `high_mark is None`); the
  original `LIMIT/OFFSET` is removed (`clear_limits`).
- If the backend lacks window functions (`not supports_over_clause`), raises
  `NotSupportedError` rather than silently degrading.

### The one obligation that can hide a bug → `(WSLICE)`
That the row-number interval `(low, high]` (1-indexed) selects **exactly** the Python
slice `[low:high]` (0-indexed). Formalized as the count contract in
`mini-orm-spec.k`:

> `count_window_slice(m, low, high) = max(0, min(m, high) − low)` for `0 ≤ low ≤ high`,
> `0 ≤ m` — and `max(0, min(m, high) − low) = len(rows[low:high])`.

i.e. the predicate keeps exactly as many rows, at exactly the positions, that Python
slicing would. See `PROOF_OBLIGATIONS.md` PO1–PO3.

## F2 — the two `get_prefetch_queryset` call sites

`create_reverse_many_to_one_manager` and `create_forward_many_to_many_manager`. Each
delegates its `__in` filter to `_filter_prefetch_queryset`. Contract: the returned
`(queryset, rel_obj_attr, instance_attr, single, cache_name, is_descriptor)` tuple is
**unchanged in shape**; only `queryset` is now the (possibly window-filtered) one. For
m2m the `_next_is_sticky()` is preserved (passed through), so the join the `__in`
lookup builds is the join the window's `partition_by` reuses (PO4), and the subsequent
`.extra(select=…)` join-table column survives the QUALIFY rewrite (PO5).

## F3 — `QuerySet._filter_or_exclude` guard (`django/db/models/query.py`)

The slice guard now reads
`if (args or kwargs) and self.query.is_sliced and not self._defer_next_filter:`.

### Intended contract
- **Eager** `filter()`/`exclude()`/`complex_filter(dict)` on a sliced queryset (the
  user-facing path, `_defer_next_filter == False`) still raises
  `TypeError("Cannot filter a query once a slice has been taken.")` — **unchanged**.
- A **deferred** filter (`_defer_next_filter == True`, set *only* internally by
  `RelatedManager._apply_rel_filters`) on a sliced queryset is allowed: it is stashed
  in `_deferred_filter` and applied later via the `query` property's
  `_filter_or_exclude_inplace` (`add_q`, no guard). This is what lets the **no-`to_attr`**
  sliced prefetch build its cached relation queryset.

### Soundness rider (why allowing it is safe — PO6/PO7)
`_defer_next_filter` is set in exactly two places (`grep`-verified): the reverse-FK and
m2m `_apply_rel_filters`. A deferred filter's result is only ever consumed by
`prefetch_one_level`'s no-`to_attr` branch, which immediately sets `qs._result_cache =
vals`; `_fetch_all` then short-circuits, so the deferred filter is **never executed to
produce SQL**. Hence relaxing the guard can never yield an incorrectly-compiled query.
