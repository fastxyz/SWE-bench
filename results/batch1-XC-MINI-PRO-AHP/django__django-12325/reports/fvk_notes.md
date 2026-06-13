# FVK notes — audit of the V1 fix for django__django-12325

This report explains, decision by decision, the outcome of applying the Formal
Verification Kit (FVK) methodology to the V1 fix in
`repo/django/db/models/base.py` (`ModelBase.__new__`, the `parent_links`
collection loop). **Outcome: V1 stands unchanged.** Every decision is traced to a
specific entry in `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`.

## What V1 is (recap)

The loop that maps each MTI parent model to the `OneToOneField` used as its parent
link previously did an unconditional `parent_links[key] = field`, so the
**last-declared** OTO to a parent won. V1 replaced the unconditional write with a
guard:

```python
existing = parent_links.get(related_key)
if (existing is not None and
        existing.remote_field.parent_link and
        not field.remote_field.parent_link):
    continue
parent_links[related_key] = field
```

i.e. *never let a plain `OneToOneField` overwrite an already-recorded
`parent_link=True` field; otherwise keep last-wins.*

## The artifacts produced

- `fvk/mti_parent_links.k` — mini-X fragment semantics of the post-filter loop
  (fields abstracted to `field(K, PL, ID)`; the V1 guard = `skip`/`updateSel`).
- `fvk/mti_parent_links-spec.k` — claims `(FOLD)` and `(SELECT-PL)` + spec-only
  abstraction functions (`anyPL`, `candOf`, `lastF`, `inF`, `keysOf`).
- `fvk/SPEC.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/FINDINGS.md`, `fvk/PROOF.md`,
  `fvk/ITERATION_GUIDANCE.md`.

The spec was *clean and easy to write* — a total biconditional postcondition plus
a fall-back and a domain clause — which is itself positive evidence (the kit's
"spec-difficulty = bug signal" inverted; see **F-9**).

---

## Decision 1 — keep V1's selection logic (the core). **No change.**

- **Traces to:** **F-2** (the bug V1 targets) and proof obligation **PO-8** with
  the closure **PO-9**, plus the order-independence corollary in `fvk/PROOF.md`
  §3.
- **Why:** `(SELECT-PL)` is proved by induction (PROOF.md §3): the loop's result
  satisfies the biconditional **I2** — `chosen.parent_link ⟺ some candidate is a
  parent_link` — *independently of declaration order*. That is exactly the
  property the issue demands ("order seems to matter? … we have explicit
  parent_link marker"). The subtle step, isolated by PO-8, is the **contrapositive
  of I2** in the overwrite branch (a plain field may overwrite only when no
  candidate so far — including itself — is a parent link); this is why I2 must be
  a *biconditional*, and V1's guard implements precisely that. V1 is correct;
  nothing to change.

## Decision 2 — do **not** "simplify" the guard to record only `parent_link=True`. **No change.**

- **Traces to:** **F-4** and **PO-12** (domain preservation), reinforced by
  **F-3**/**PO-13**.
- **Why:** The tempting one-liner `if isinstance(field, OneToOneField) and
  field.remote_field.parent_link:` would remove lone non-parent OTOs from
  `parent_links`. PO-12 shows V1 inserts a key on its *first* candidate and never
  drops keys, so `keys(parent_links)` equals the original's exactly (clause
  **D**). The "simplified" variant would violate D for the single-OTO case,
  auto-create `place_ptr`, and **break**
  `invalid_models_tests…test_missing_parent_link` (F-4). Keeping V1's fallback
  (clause **I3**, PROOF.md §3 INV(3)) preserves that contract. V1's shape is the
  *correct* one; this confirms the V1 baseline's "rejected alternatives" reasoning
  formally.

## Decision 3 — accept the two attribute reads as crash-free. **No change.**

- **Traces to:** **F-1** and **PO-1/PO-2/PO-3**.
- **Why:** V1 added `existing.remote_field.parent_link` /
  `field.remote_field.parent_link`. PO-1 shows the read is gated by `existing is
  not None` (Python `and` short-circuit, modelled by `skip` reading `M[K]` only
  under `K in_keys(M)`), and PO-2 shows `existing` is always a `OneToOneField`,
  which always carries `remote_field.parent_link` (verified in
  `repo/django/db/models/fields/related.py:461-470`). No missing precondition, no
  guard to add.

## Decision 4 — treat the secondary "`document_ptr_id` not populated" symptom as already fixed. **No change.**

- **Traces to:** **F-8** (proof-derived).
- **Why:** Tracing the consumer chain (`parent_links` → `_meta.parents` →
  `Options._prepare` *and* `Model._set_pk_val`, base.py:583-587) shows both issue
  symptoms share one root cause: the wrong field being recorded as the link. I2
  selects the correct field for either order, so `_set_pk_val` writes the pk into
  `document_ptr.target_field` and the column is populated. One selection fix
  covers both symptoms — no second code site needs editing.

## Decision 5 — leave the multiple-parent-link and multi-OTO-error edge cases alone. **No change.**

- **Traces to:** **F-6** and **F-7** (both classified OUT-OF-SCOPE,
  proof-derived); no proof obligation requires closing them.
- **Why:** F-7 (two `parent_link=True` OTOs to one parent) is silently
  de-duplicated by last-wins — but this is *pre-existing* (the original code did
  likewise) and orthogonal to this issue (parent-link vs. non-parent-link). F-6
  (which field the missing-link error names) is cosmetic and order-dependent in
  both old and new code. Changing either would be scope creep and risk new
  regressions. They are logged as optional, *separate* future work in
  `fvk/ITERATION_GUIDANCE.md` G-2/G-3, not as edits here.

## Decision 6 — do not claim machine-checked; mark the inductive VCs as escalation. **Honesty gate.**

- **Traces to:** **PO-7, PO-8, PO-11, PO-14** (tagged `[ESC]`) and the
  proof-derived row in `fvk/FINDINGS.md`.
- **Why:** The selection-correctness VCs reduce to inductive facts about
  `anyPL`/`candOf`/`lastF` over a symbolic list, which the bundled arithmetic
  `[simplification]` tier does not machine-discharge. Per the kit's honesty gate,
  these are named `[ESCALATION BOUNDARY]`, **hand-proved in full** (PROOF.md
  §3–§4), and **never** admitted as `[trusted]`. This is a *tooling-tier
  capability* gap, **not** a correctness gap in V1 — so it does not change the
  "V1 stands" conclusion; it only conditions the (advisory, and here moot) test-
  redundancy recommendation on a future `kprove` run.

---

## Net result

| Decision | Trace | Code change? |
|---|---|---|
| Keep core selection logic | F-2, PO-8/PO-9 | No |
| Keep *skip*-form (not "record parent_link only") | F-4, PO-12/PO-13 | No |
| Accept attribute reads as safe | F-1, PO-1/PO-2/PO-3 | No |
| Secondary symptom already covered | F-8 | No |
| Leave F-6/F-7 edge cases | F-6, F-7 | No |
| Escalation honesty for inductive VCs | PO-7/PO-8/PO-11/PO-14 | No |

**No source files under `repo/` were modified in this pass.** The FVK audit
confirms V1 satisfies its specification (I1 ∧ I2 ∧ I3 ∧ D) and resolves both
reported symptoms, with the only residual being the deferred *machine* check of
list-inductive VCs — a verification-tooling limitation, not a defect. V1 stands.
