# ITERATION_GUIDANCE.md — feedback for the next code/spec/intent pass

Per `verify.md` step 3, `/verify` is a critic for the whole
generate→formalize→verify loop. Below: the proof-derived findings as **actionable**
entries (evidence → classification → UltimatePowers question → recommended change →
tests), then the verdict on V1.

---

## Verdict: **V1 stands, unchanged.**

Every proof obligation in `PROOF_OBLIGATIONS.md` is DISCHARGED,
DISCHARGED-BY-INVARIANT, or ASSUMED-BACKEND (the last being inherited unchanged
from V0). No obligation is open as a *code bug*. The two boundary findings (F3, F4)
are real but are (a) outside the issue's scope, (b) matched to the intended
upstream design, and (c) safe on every reachable in-tree input. Changing the code
for them would be unjustified scope creep that contradicts the base-backend
contract. The audit therefore **confirms** the fix rather than revising it.

---

## Actionable entries

### A. F3 — combined query uses `m × batch` parameters on uncapped backends

- **Evidence:** PO-BATCH; `get_del_batches → bulk_batch_size`; base
  `bulk_batch_size` returns `len(objs)` (`max_query_params = None`), SQLite/Oracle
  divide by `len(fields)`.
- **Classification:** design-inherited boundary / backend-contract assumption —
  **not** a code bug introduced by the fix.
- **UltimatePowers question (Q-A):** "On PostgreSQL/MySQL, should a fast-delete
  that merges `m` foreign keys cap its batch at `ceiling // m` (chunking large
  deletions), or is the existing `bulk_batch_size = len(objs)` ‘no chunking’
  contract authoritative for these backends?" (Upstream answer to date: the
  latter — the per-backend hook is the single source of truth, and base backends
  opt out of chunking.)
- **Recommended change:** **none in this fix.** If a future ticket wants
  protection, the *correct* locus is the backend `bulk_batch_size` (e.g. give the
  base backend a finite `max_query_params`), not `Collector` — keeping the field
  count threaded through `get_del_batches` (which V1 already does) is the enabling
  half and is in place.
- **Tests:** KEEP any large-deletion test on uncapped backends; ADD (in a future
  scope, not here — tests are fixed/hidden) a regression for `m·len(O)` near the
  driver ceiling if base `bulk_batch_size` is ever made finite.

### B. F6 — `related_objects` / `get_del_batches` public signatures changed

- **Evidence:** PO-COMPAT; `NestedObjects.related_objects` updated;
  `NoFastDeleteCollector` unaffected; the in-code comment marks `related_objects`
  as an override point ("the rare cases where `.related_objects` is overridden").
- **Classification:** intended, upstream-sanctioned API change for the feature.
- **UltimatePowers question (Q-B):** "Are third-party `Collector` subclasses that
  override `related_objects(self, related, objs)` in scope? They must migrate to
  `(self, related_model, related_fields, objs)`." (Acceptable break — it ships
  with the feature; worth a release-note line.)
- **Recommended change:** none to logic; a release-note mention is the only
  optional follow-up (docs not edited here to keep the change minimal/targeted).
- **Tests:** KEEP the admin nested-delete tests (exercise the migrated override).

### C. F4 — `reduce(or_, related_fields)` non-empty precondition

- **Evidence:** PO-NONEMPTY; three call sites all pass ≥1 field.
- **Classification:** latent robustness precondition, discharged by a call-site
  invariant (unreachable bad input in-tree).
- **UltimatePowers question (Q-C):** "Should `related_objects` defensively reject
  empty `related_fields`, or is the call-site invariant a sufficient contract?"
- **Recommended change:** none (matches upstream `reduce(or_, …)`); if the method
  is ever promoted to documented public API, add `assert related_fields`.
- **Tests:** none needed (no reachable path).

### D. Spec/intent corroboration (positive signal)

- **Evidence:** a single clean closed form (`rows = bigU`) and a clean union loop
  invariant were writable on the first try (FINDINGS spec-difficulty check).
- **Classification:** corroborating evidence the algorithm is correct (the kit's
  "easy clean spec ⇒ likely-correct" heuristic).
- **Recommended change:** none.

---

## If a repair pass were ever requested (it was not)

The only defensible micro-edits, each traceable to a finding, would be:
1. a one-line `assert related_fields` in `related_objects` (F4/Q-C) — **declined**:
   adds nothing on any reachable path and diverges from upstream;
2. a release-note/docstring line for the signature change (F6/Q-B) — **declined
   here**: docs are out of the minimal-fix scope and tests are hidden/fixed.

Neither is a correctness fix. V1 is therefore left exactly as-is.

---

## Hand-off package

`fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, this
file, and the `.k` artifacts (`fvk/mini-deletion.k`, `fvk/mini-deletion-spec.k`)
constitute the evidence package. Next step to *machine-verify* (not done here):
run PROOF.md §J and confirm `kprove ⇒ #Top`, after which the §M test-redundancy
recommendations become safe to act on.
