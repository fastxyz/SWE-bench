# PROOF_OBLIGATIONS.md — what must hold for the V1 fix to be correct

Each obligation has: statement, why it matters, how it is discharged (and by which
`fvk/mini-deletion-spec.k` claim / arithmetic VC), and its status. **Status
vocabulary:** **DISCHARGED** (constructed proof, not machine-checked) ·
**DISCHARGED-BY-INVARIANT** (holds via an in-tree call-site invariant) ·
**ASSUMED-BACKEND** (delegated to a documented backend contract) ·
**ESCALATION BOUNDARY** (named, routed, not faked as trusted).

The obligations are what the issue's intent ("combine the queries, change nothing
observable about the result") decomposes into.

---

## PO-ROWSET — deleted row set is invariant under OR-combination  *(central)*

**Statement.** For each fast-deletable table `t` with grouped FK fields
`f_0..f_{m-1}` and deleted objects `O`, the set of `t`-rows V1 deletes equals the
set V0 deletes:
`rows(⋁_{k} Q(f_k__in=O)) = ⋃_{k} S_k` where `S_k = {r∈t : r.f_k ∈ O}`.

**Why.** The whole correctness of the feature: combining must not add or drop a
row.

**Discharge.** The `rows()` homomorphism `rows(p or q) = rows(p) ∪ rows(q)`
(PROOF §A), applied by induction over the fold = the `(COMBINE)` claim
`rows(result) = bigU(0,m) = S_0 ∪ … ∪ S_{m-1}`. V0 deletes `⋃_k S_k` because
sequential deletes of overlapping sets remove their union (PROOF §C). **Status:
DISCHARGED.**

## PO-COUNT — reported per-table deleted count is invariant

**Statement.** `deleted_counter[t.label]` is the same in V1 and V0.

**Why.** `delete()` returns `(total, per-label)`; tests assert these.

**Discharge.** V1 reports `|rows(combined)| = |⋃_k S_k|` (one `rowcount`). V0
reports `Σ_k |S_k \ (S_0∪…∪S_{k-1})| = |⋃_k S_k|` (telescoping union cardinality).
Equal by PO-ROWSET + finite inclusion–exclusion (PROOF §C). **Status: DISCHARGED.**

## PO-FEWER — V1 issues no more fast-delete statements than V0 (the goal)

**Statement.** `#combined_DELETEs(t) ≤ #perfield_DELETEs(t)`, strict when `m ≥ 2`
and a single batch suffices.

**Why.** This *is* the optimization the issue asks for.

**Discharge.** Per table, V0 = `Σ_{k} ceil(|O| / b_1)` (b_1 = single-field batch);
V1 = `ceil(|O| / b_m)` with `b_m = bulk_batch_size(m fields)`. For uncapped
backends `b_1 = b_m = |O|` ⇒ V0 = `m`, V1 = `1` (m-fold reduction). For SQLite
`b_1 = 500`, `b_m = 999//m`: V1 ≤ V0 (e.g. m=2, |O|=1000 ⇒ V0=4, V1=3). Never
greater (PROOF §D). **Status: DISCHARGED** (arithmetic VC, Z3-tier).

## PO-DECISION — V1's per-relation fast-delete decision equals V0's per-queryset one

**Statement.** `can_fast_delete(related_model, from_field=f)` (V1) returns the same
boolean as `can_fast_delete(related_objects(related, batch), from_field=f)` (V0).

**Why.** If the classification differed, V1 could fast-delete something V0
cascaded (or vice-versa) — a real behavior change.

**Discharge.** `can_fast_delete` reads only `model(x)` and `f`; V0 derived
`model = queryset.model = related_model`, V1 derives `model =
related_model._meta.model = related_model`. Same model, same `f` ⇒ same result
(Finding F1; PROOF §E). **Status: DISCHARGED.**

## PO-ORDER — combining/reordering fast deletes is sound

**Statement.** The result of the fast-delete phase is independent of the order of
`self.fast_deletes` and of which entries are merged.

**Why.** V1 changes both the order and the grouping.

**Discharge.** Fast-deletable `t` ⇒ every relation into `t` is `DO_NOTHING` and
`t` has no signals/GFK ⇒ no two fast-deletable tables have a cascade edge ⇒ no
delete-order constraint among them; and all fast deletes precede all regular
deletes within one `atomic`. So any order/grouping yields the same final DB state
(Finding F5; PROOF §F). **Status: DISCHARGED.**

## PO-BATCH — each combined query respects the parameter budget

**Statement.** A combined query over a batch `B_j` uses `m·|B_j|` parameters
`≤` the backend's safe budget.

**Why.** Exceeding it raises a DB error.

**Discharge.**
- Capped backends (SQLite, Oracle): `bulk_batch_size = max_query_params // m`, so
  `m·|B_j| ≤ m·(max_query_params//m) ≤ max_query_params`, **provided
  `m ≤ max_query_params`** (PROOF §G; Z3-tier linear VC).
- Uncapped backends (PostgreSQL, MySQL, `max_query_params=None`):
  `bulk_batch_size = len(O)`, i.e. the backend declares any size safe; V1 trusts
  that declaration exactly as V0 did for single fields. The residual edge
  `m·len(O) > driver-ceiling` is **ASSUMED-BACKEND** — inherited unchanged from
  the base backend's intentional contract (Finding F3).

**Status: DISCHARGED for capped backends (with the stated precondition);
ASSUMED-BACKEND for uncapped.** Not faked as trusted — the precondition is named.

## PO-NONEMPTY — `reduce(or_, related_fields)` is always called non-empty

**Statement.** Every call to `related_objects` has `len(related_fields) ≥ 1`.

**Discharge.** Static inspection of the three call sites (Finding F4): non-fast
path passes `[field]`; fast path iterates `model_fast_deletes` keys (each created
by `≥1` append); admin override forwards the non-fast `[field]`. **Status:
DISCHARGED-BY-INVARIANT.**

## PO-LAZY / PO-DIRECT — no premature evaluation; single direct DELETE

**Statement.** The combined queryset is built lazily and `_raw_delete` →
`delete_qs` emits one direct `DELETE … WHERE … OR …`, not a subquery.

**Discharge.** The fast path appends the queryset with no truthiness check (as
V0); `Q(f__in=batch)` filters a direct FK column so `innerq.alias_map` is just the
base table ⇒ `delete_qs` copies the WHERE clause directly (Finding F7; PROOF §H).
**Status: DISCHARGED** (single-table no-join argument; the live lookup compiler is
the escalation point below).

## PO-COMPAT — single-field path is byte-compatible; overrides updated

**Statement.** With `fields == [field]`, V1 `get_del_batches`/`related_objects`
produce the same batches/queryset as V0; in-tree overrides are migrated.

**Discharge.** `field_names == [field.name]` (identical `bulk_batch_size` arg) and
`reduce(or_, [Q(field__in=objs)]) == Q(field__in=objs)`; `NestedObjects` updated,
`NoFastDeleteCollector` unaffected (Findings F6). **Status: DISCHARGED.**

## PO-IMPORT — the new imports do not create a circular import

**Statement.** `from django.db.models import query_utils, …` in `deletion.py` is
safe even though `deletion` is imported early by `django.db.models.__init__`.

**Discharge.** `query_utils` imports only `constants` + `utils.tree` (no
`deletion`); `from package import submodule` resolves the submodule directly,
independent of `__init__` ordering (PROOF §I). **Status: DISCHARGED.**

---

## Escalation boundary (named, not hidden)

**EB-1 — ORM lookup compilation.** That `Q(fk__in=objs)` compiles to a *join-free*
`fk_id IN (…)` (so PO-DIRECT holds and the OR introduces no join) is a property of
the live `django.db.models.sql` compiler, **outside** the mini-X fragment. It is
relied on (and is the long-standing behavior V0 also relied on) but not re-derived
in K. Route: `django/db/models/sql/where.py`, `query.build_filter`. Not faked as
`[trusted]`; stated as an assumption with its source.

**EB-2 — backend parameter ceilings.** The numeric driver ceilings behind
PO-BATCH's uncapped case (psycopg2/mysqlclient) are environment facts, not code;
ASSUMED-BACKEND, consistent with V0.
