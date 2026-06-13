# PROOF_OBLIGATIONS.md — django__django-15957

The verification conditions the V1 fix must satisfy. Status legend:
**PROVEN** (discharged in `PROOF.md` over `mini-orm*.k`, constructed-not-machine-checked) ·
**TRUSTED** (relies on a pre-existing Django/SQL component in the trusted base; argued,
not re-proved) · **OUT-OF-DOMAIN** (deliberately not supported; tracked as a Finding).

---

## Core arithmetic (the off-by-one — where a bug would hide)

### PO1 — interval ↔ slice, bounded case — **PROVEN**
For `0 ≤ low ≤ high`, `0 ≤ m`: the set of 1-indexed positions `{ k : 1≤k≤m ∧ low<k≤high }`
equals the positions Python `rows[low:high]` selects, and its size is
`max(0, min(m,high) − low)`.
*Why it matters:* the bug class here is `>` vs `>=` / `<` vs `<=`. V1 emits
`GreaterThan(win, low)` = `k > low` and `LessThanOrEqual(win, high)` = `k ≤ high`.
Positions kept = `{low+1, …, min(m,high)}` = 0-indexed `{low, …, min(m,high)−1}` =
`rows[low:high]`. Discharged by `(WSLICE)` + `(WLOOP)`; the linear VCs go to Z3.

### PO2 — `high is None` (offset-only, e.g. `qs[2:]`) — **PROVEN**
When `high_mark is None` V1 adds only `GreaterThan(win, low)`. Positions kept
`{ k : low<k≤m }`, size `max(0, m − low)` = `len(rows[low:])`. This is PO1 with
`high ≥ m` (so `min(m,high)=m`); same claim, `LessThanOrEqual` branch dropped.

### PO3 — slice composition (`qs[a:b][c:d]`) — **PROVEN (via Query.set_limits)**
Chained slices compose in `Query.set_limits` *before* the helper sees them: it reads the
already-composed `low_mark`/`high_mark`. PO1 then applies to the final marks. Verified by
arithmetic: `set_limits` yields `low' = min(high, low+c)`, `high' = min(high, low+d)`,
preserving `0 ≤ low' ≤ high'` (the `(WSLICE)`/`(WLOOP)` precondition). No new obligation
beyond PO1.

### PO0 — boundary marks — **PROVEN (subsumed by PO1)**
- `low=high` ⇒ `set_empty()` upstream **and** `cf = max(0, min(m,high)−low) = 0`: consistent.
- `low=0, high=n` (`qs[:n]`) ⇒ `k>0` always true, so the kept set is `{1,…,min(m,n)}`,
  size `min(m,n)` = `len(rows[:n])`. The redundant `k>0` term changes the size by 0
  (Finding 4). `cf` at `low=0` = `max(0, min(m,high))` = `min(m,high)`: consistent.

## Integration (trusted base — pre-existing Django machinery)

### PO4 — partition groups by the correct parent — **TRUSTED**
The window's `partition_by=field_name` must reference the *same* relation column as the
`field_name__in` lookup, so each related row is ranked within its own parent's group.
V1 builds **one** `Q` (the `__in` predicate `&` the window lookups) and applies it in a
**single** `queryset.filter(predicate)` call; within one `add_q` resolution Django reuses
the join for an identical path. For m2m the `_next_is_sticky()` (preserved by V1) makes
that join reuse explicit across the through-table. *Trusted:* Django join reuse +
F-expression resolution. Not re-proved here; argued in PROOF.md §Trusted base.

### PO5 — window-in-WHERE compilation preserves the m2m extra-select — **TRUSTED (spot-checked)**
The m2m descriptor adds `.extra(select={"_prefetch_related_val_*": "join.col"})` and
`rel_obj_attr` reads those columns back. With a window predicate in the WHERE the compiler
runs the QUALIFY rewrite (`SQLCompiler.get_qualify_sql`): `SELECT * FROM (inner) qualify
WHERE …`. Spot-checked `compiler.py:296–313`: extra-select columns carry an explicit
non-`None` alias, so `with_col_aliases=True` does **not** rename them (only `alias is None`
model columns become `colN`); the masking branch re-selects `select.values()`, which
includes those aliases. So `_prefetch_related_val_*` survives to the outer row. *Trusted:*
the window-filtering feature (`split_having_qualify` / `get_qualify_sql`) itself, which
pre-exists this fix.

### PO6 — a deferred filter is never executed — **PROVEN (control-flow)**
In the no-`to_attr` path, `_apply_rel_filters(lookup.queryset)` returns a queryset with a
*stashed* (`_deferred_filter`) core filter on a still-sliced query; `prefetch_one_level`
then sets `qs._result_cache = vals`. `QuerySet._fetch_all` returns early when
`_result_cache is not None`, so the deferred filter / sliced query is never compiled to
SQL. Therefore the relaxed guard (PO7) cannot emit a wrong query. Traced in PROOF.md §4.

### PO7 — the guard relaxation is contained — **PROVEN (whole-repo grep)**
`grep` shows `_defer_next_filter = True` is set in exactly two internal spots (both
`_apply_rel_filters`). Hence the new `and not self._defer_next_filter` clause changes
behaviour **only** for those internal callers; every user-facing eager
`filter()`/`exclude()` keeps `_defer_next_filter == False` and still raises. Existing
tests confirm the boundary: `queries…test_slicing_cannot_filter_queryset_once_sliced`
(non-deferred → still raises) and `queryset_pickle…test_filter_deferred` (deferred but
**not** sliced → unaffected by the new `is_sliced` clause).

## Out-of-domain (intentional non-support — Findings, not bugs)

### PO8 — single-valued relations (forward-FK, reverse-O2O) — **OUT-OF-DOMAIN**
`get_prefetch_queryset` there still does `queryset.filter(**query)`; a sliced queryset
raises. Slicing a ≤1-per-parent relation is not meaningful (a single global slice would
be wrong). Left raising — Finding 6.

### PO9 — GenericRelation prefetch — **OUT-OF-DOMAIN**
Its prefetch query groups by content-type with OR-ed predicates; a correct partition needs
`(content_type, object_id)`. Out of scope for this ticket — Finding 7.
