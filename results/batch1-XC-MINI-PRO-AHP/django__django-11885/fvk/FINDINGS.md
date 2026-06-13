# FINDINGS.md — plain-language findings for `django__django-11885` V1

Each finding is `input → observed vs expected`, classified, with the next action.
Most are **positive** (the spec confirms the fix); two are genuine **boundary**
findings the spec flushed out. None blocks; none required a V1 code change — the
justification for "V1 stands" is in `reports/fvk_notes.md`, traced to these IDs.

Severity legend: **[OK]** confirmed correct · **[BOUNDARY]** correct on the
intended domain, with a precisely-stated edge · **[COMPAT]** API/compat note.

---

## F1 — [OK] `type(objs)` → `objs._meta.model` is behavior-preserving and enabling

- **Input:** every value V0 passed to `can_fast_delete` — a model **instance**
  (e.g. `delete()`'s single-object fast path) or a **queryset** (collect's
  fast-delete probe).
- **Observed (V1):** instance → `obj._meta.model`; queryset → unchanged `.model`
  branch. **Expected:** identical boolean to V0. `obj._meta.model is type(obj)`
  for concrete, proxy, and MTI-child instances because `Options.model` is the
  class that owns the `Options`. ✓
- **New capability:** a model **class** `C` is now accepted
  (`C._meta.model is C`); V0's `type(C)` would have returned the metaclass and
  then crashed at `model._meta`. This is what lets `collect` decide
  fast-deletability **once per relation, before** building a queryset — the
  precondition for grouping.
- **Class:** confirmed-correct / enabling change. **Action:** none.

## F2 — [OK] OR-combination preserves the deleted row set AND the reported count

- **Input:** a table `t` with FK fields `f_0..f_{m-1}` to the deleted objects `O`;
  let `S_k = {rows of t : t.f_k ∈ O}`.
- **Observed (V1):** one query deletes `rows(⋁_k Q(f_k__in=O)) = S_0 ∪ … ∪ S_{m-1}`
  and reports `|S_0 ∪ … ∪ S_{m-1}|`.
- **V0:** `m` sequential queries; query `k` deletes `S_k` minus rows already
  deleted by `0..k-1`; the rowcounts **telescope** to `|S_0 ∪ … ∪ S_{m-1}|`.
- **Expected:** equal deleted set and equal total. ✓ — verified on the overlap
  cases too (self-referential `person_friends` with a `(P,P)` self-row; an
  `Entry` with `created_by == updated_by == U`): V0 total `3` = V1 total `3`.
- **Class:** confirmed-correct (the central correctness property). **Proof:**
  `PO-ROWSET`, `PO-COUNT`; `(COMBINE)` claim. **Action:** none.

## F3 — [BOUNDARY] combined query's parameter count is `m × batch`; backend-dependent

- **Input:** deleting `len(O)` objects where table `t` has `m ≥ 2` CASCADE FKs to
  the deleted model, on a backend whose `bulk_batch_size` **ignores** field count.
- **Observed (V1):** `get_del_batches(O, fields)` calls
  `bulk_batch_size([m field names], O)`.
  - **SQLite** (`max_query_params=999`) and **Oracle** (`65535`) return
    `max_query_params // m`, so a combined batch carries `m · (limit//m) ≤ limit`
    parameters. **Safe**, provided `m ≤ max_query_params` (else `max(…,1)` clamps
    the batch to 1 and a `t` with `> max_query_params` FKs to one model would
    exceed the limit — physically impossible: that many same-target FKs in one
    table is not a real schema).
  - **PostgreSQL / MySQL** (`max_query_params=None`) return `len(O)` regardless of
    `m`. The combined query then has `m · len(O)` bind parameters, i.e. **`m ×`**
    a V0 single-field query (`len(O)`). If `m · len(O)` exceeds the driver's
    bind-parameter ceiling (PostgreSQL extended-protocol 65535), V1 errors where
    V0's per-field queries (`len(O)` each) would not.
- **Expected (intent):** combine queries *and* respect the backend's parameter
  budget. V1 respects it **exactly to the extent the backend's `bulk_batch_size`
  encodes it** — which is the correct and only hook available (it is what the fix
  threads the field list into). SQLite/Oracle honor it; the base backends
  *deliberately* return `len(objs)` ("no chunking needed"), an **unchanged,
  pre-existing** stance that V0 also trusted for single-field IN deletes.
- **Class:** correct-on-intended-domain + design-inherited boundary. The precise
  precondition is **`m · batch_size ≤ backend bind-parameter ceiling`**, enforced
  for capped backends by `get_del_batches` and assumed (as before the fix) for
  uncapped ones. **Action: no V1 change** — fixing it would mean changing base
  `bulk_batch_size` for *all* deletes, which is out of this issue's scope and
  contradicts the base backend's intentional contract. Surface as an
  UltimatePowers question (ITERATION_GUIDANCE Q-A) and a **kept** test class.

## F4 — [BOUNDARY] `related_objects` requires `related_fields` non-empty

- **Input:** `related_objects(t, [], objs)`.
- **Observed (V1):** `reduce(operator.or_, ())` → `TypeError: reduce() of empty
  iterable with no initial value`.
- **Expected:** a queryset (or no call at all).
- **Resolution:** the precondition **holds at every call site**: the non-fast path
  always passes `[field]`; the fast path iterates `model_fast_deletes.items()`,
  whose keys exist only because `≥ 1` field was appended; the admin/contenttypes
  overrides only reach the non-fast `[field]` path. So the bad input is
  **unreachable** in-tree (`PO-NONEMPTY`).
- **Class:** latent robustness precondition, currently discharged by a call-site
  invariant; matches upstream (upstream also uses bare `reduce(or_, …)`).
  **Action: no V1 change.** If `related_objects` were ever exposed as a public
  extension point taking arbitrary field lists, add an `assert related_fields`.

## F5 — [OK] fast deletes have no inter-dependencies ⇒ grouping/reordering is sound

- **Input:** the relative order of entries in `self.fast_deletes`, which V1
  changes (a model's grouped fast deletes are appended after its non-fast
  relations are processed).
- **Observed/Expected:** a model `t` is fast-deletable **iff** every relation
  pointing at `t` is `DO_NOTHING` and `t` has no signals/GFK; hence no
  fast-deletable model participates in a cascade, so no two of them have a delete
  ordering constraint, and all fast deletes run before any regular delete inside
  the same `atomic` block. Reordering them is invisible. ✓
- **Class:** confirmed-correct. **Proof:** `PO-ORDER`. **Action:** none.

## F6 — [COMPAT] signature changes are matched at all in-tree call sites/overrides

- **Input:** `related_objects` / `get_del_batches` signature changes.
- **Observed:** the only in-tree override of `related_objects` is
  `NestedObjects` (admin) — **updated** to `(related_model, related_fields, objs)`
  with `select_related(*[f.name for f in related_fields])` (identical to V0 for
  the single field it ever receives). `NoFastDeleteCollector` (contenttypes)
  overrides only `can_fast_delete` → unaffected. No other module calls these
  helpers. ✓
- **Class:** compatibility, fully handled. **Action:** none. (Public-API note:
  these are documented as the "rare cases where `.related_objects` is overridden"
  extension points; third-party overriders would need the new signature — an
  acceptable, upstream-sanctioned break for this feature. ITERATION_GUIDANCE Q-B.)

## F7 — [OK] no premature query evaluation; combined query stays a single direct DELETE

- **Input:** the lazy combined queryset handed to `_raw_delete` → `delete_qs`.
- **Observed:** `Q(f_i__in=batch)` filters a **direct FK column** (`f_i_id`), so
  the OR predicate uses only the base table — `delete_qs` copies the WHERE clause
  directly (`DELETE FROM t WHERE f0_id IN (…) OR f1_id IN (…)`), never falling to
  the subquery branch; and the fast path never forces evaluation (no
  `if sub_objs:`), exactly as V0.
- **Class:** confirmed-correct. **Proof:** `PO-LAZY`, `PO-DIRECT`. **Action:** none.

---

## Spec-difficulty check (formalize.md §7)

A **clean** spec was writable: the postcondition is a single closed form
(`rows(result) = bigU(0, m)`), the loop has a clean union invariant, and the only
side conditions are natural (`m ≥ 1`; the per-backend parameter budget). Per the
methodology, "easy clean spec" is corroborating evidence the code is right. The
**one** place difficulty appeared — having to state the parameter-budget side
condition explicitly (F3) — is exactly the kind of silently-assumed precondition
the kit is meant to surface; it is reported rather than papered over.
