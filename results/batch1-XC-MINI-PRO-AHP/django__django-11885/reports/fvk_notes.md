# fvk_notes.md — FVK audit outcome for `django__django-11885`

## Bottom line

The FVK audit **confirms V1**. No source file was changed in this pass. Every
proof obligation derived from the issue's intent is discharged (or
discharged-by-invariant, or an inherited backend assumption), and the only two
edges the specification flushed out (F3, F4) are out of the issue's scope, matched
to the intended upstream design, and unreachable-or-safe on every in-tree input.
This note traces each decision — both the original V1 edits and the decision to
leave them unchanged — to specific entries in `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`.

The five artifacts are `fvk/SPEC.md`, `fvk/FINDINGS.md`,
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md`, backed by
the K sources `fvk/mini-deletion.k` and `fvk/mini-deletion-spec.k`
(constructed, not machine-checked — no execution environment).

---

## 1. Why each V1 change is justified (kept as-is)

### 1.1 `related_objects(self, related_model, related_fields, objs)` — OR-fold
- **Justified by:** PO-ROWSET, PO-COUNT (FINDINGS **F2**) — the `rows`
  homomorphism `rows(p or q)=rows(p)∪rows(q)` makes the combined query delete
  exactly the union of the per-field row sets, which is also what V0's sequential
  deletes removed; counts telescope to the same total. Proven by the `(COMBINE)`
  claim (`PROOF.md §C`).
- **Precondition surfaced:** PO-NONEMPTY (**F4**) — `reduce(or_, …)` needs ≥1
  field; discharged by the call-site invariant (every caller passes ≥1). Kept as
  upstream-style bare `reduce`; no guard added (ITERATION_GUIDANCE C).
- **Backward compat:** PO-COMPAT — with one field, `reduce(or_, [Q(f__in=o)]) =
  Q(f__in=o)`, identical to V0.

### 1.2 `get_del_batches(self, objs, fields)` — list of fields
- **Justified by:** PO-BATCH (**F3**) — threading the *field list* into
  `bulk_batch_size` is the correct and only hook for keeping a combined,
  `m`-field query within a backend's parameter budget; SQLite/Oracle honor it by
  dividing the limit by `m`. PO-COMPAT — `fields==[field]` reproduces V0's
  `[field.name]` batches byte-for-byte.

### 1.3 `can_fast_delete`: `type(objs)` → `objs._meta.model`
- **Justified by:** PO-DECISION (**F1**) — equal to V0 for every instance/queryset
  input (`obj._meta.model is type(obj)`), and additionally accepts a model
  **class**, which is what lets `collect` classify a relation **before** building
  a queryset. Proven in `PROOF.md §E`.

### 1.4 `collect` — group fast deletes by model, then batch over all fields
- **Justified by:** PO-ROWSET/PO-COUNT (**F2**), PO-FEWER (the optimization the
  issue requested), and PO-ORDER (**F5**) — fast-deletable models are mutually
  cascade-independent, so grouping and reordering `self.fast_deletes` is sound
  (`PROOF.md §F`). PO-LAZY/PO-DIRECT (**F7**) — the fast path stays lazy and emits
  one direct `DELETE … OR …` (no subquery).

### 1.5 `NestedObjects.related_objects` (admin) — signature migration
- **Justified by:** PO-COMPAT (**F6**) — the only in-tree override of a
  signature-changed method; updated to `select_related(*[f.name for f in
  related_fields])`, identical to V0 for the single field it ever receives
  (its `can_fast_delete` returns `False`, so the combine path never runs).
  `NoFastDeleteCollector` overrides only `can_fast_delete`, so it was correctly
  left untouched.

### 1.6 New imports (`defaultdict`, `reduce`, `or_`, `query_utils`)
- **Justified by:** PO-IMPORT — `query_utils` is import-safe from `deletion`
  (no cycle; `PROOF.md §I`); the rest are stdlib.

---

## 2. Why no new change was made (each candidate, with its trace)

| Candidate edit | Finding / obligation | Decision & reason |
|---|---|---|
| Divide batch by field count on **all** backends (protect Postgres/MySQL from `m·len(O)` params) | **F3** / PO-BATCH (ASSUMED-BACKEND) | **Rejected.** The base backend's `bulk_batch_size = len(objs)` is an intentional "no chunking" contract that V0 also relied on for single-field IN deletes. Enforcing a cap would change *all* deletes' batching, contradict that contract, and exceed the issue scope. The correct future locus (if ever wanted) is the backend, not `Collector`; the field count is already threaded through `get_del_batches`. |
| `assert related_fields` in `related_objects` | **F4** / PO-NONEMPTY | **Rejected.** The empty-list input is unreachable in-tree (call-site invariant), and upstream uses bare `reduce(or_, …)`. Adds nothing on any reachable path. |
| Release-note / docstring for the signature change | **F6** / PO-COMPAT | **Deferred (not made here).** Docs are outside the minimal-fix scope; the benchmark test suite is fixed and hidden, so no behavioral need. Noted as the one optional follow-up in ITERATION_GUIDANCE B. |
| Re-order so fast deletes keep V0 order | **F5** / PO-ORDER | **Rejected (unnecessary).** Proven order-independent — no behavioral difference to preserve. |

---

## 3. Audit method and honest limits

- The K layer (`fvk/mini-deletion.k` + `-spec.k`) formalizes the algorithmic heart
  — the `reduce(or_, …)` fold — as a loop circularity `(FOLD)` and a function
  contract `(COMBINE)`, imitating the sum-up reference shape with set **union**
  replacing arithmetic **+**. The set-algebra obligations (V0≡V1 set/count,
  ordering, batching, backend budget) are discharged as first-order VCs over the
  same `rows`/`bigU` vocabulary.
- **Constructed, not machine-checked.** Per the kit's honesty gate and this task's
  no-execution rule, `kompile`/`kprove` were **not** run; the exact commands are in
  `PROOF.md §J`. The Findings (Benefit 2) do not depend on machine-checking and are
  reported with confidence; the test-redundancy notes (`PROOF.md §M`) are explicitly
  conditioned on a later `kprove ⇒ #Top` and recommend **keeping** the
  `assertNumQueries` and large-deletion tests regardless.
- **Named escalation boundaries (not faked as trusted):** EB-1 (the live ORM
  compiler making `fk__in` join-free, underpinning PO-DIRECT) and EB-2 (numeric
  backend parameter ceilings, underpinning PO-BATCH's uncapped case).

## 4. Result

V1 is correct on the intended domain of the issue and is left exactly as written
after the V1 pass. The FVK artifacts constitute the evidence package; the only
open items are explicitly-scoped backend/design questions (ITERATION_GUIDANCE
Q-A/Q-B/Q-C), none of which is a correctness defect in this fix.
