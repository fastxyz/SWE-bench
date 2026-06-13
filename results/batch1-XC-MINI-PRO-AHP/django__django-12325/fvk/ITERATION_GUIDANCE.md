# ITERATION GUIDANCE — next-pass feedback for the parent-link fix

Actionable feedback distilled from `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`. Each item: **evidence → classification →
UltimatePowers question → recommended next change → tests**.

---

## Decision for THIS pass: **V1 stands unchanged.**

The audit closed every correctness obligation (PO-1..PO-13 logically; PO-7/PO-8/
PO-11/PO-14 hand-proved, machine check deferred as a tooling-tier gap). No
finding maps to a defect in V1. Per `commands/verify.md` ("do not silently
regenerate or patch code … unless the user explicitly asks for a repair pass")
and the task's "if V1 is already correct … it may stand unchanged", the source
under `repo/` is **not modified** in this pass. Justification is traced
finding-by-finding in `reports/fvk_notes.md`.

---

## G-1. Keep the guard in its current *skip* form (do **not** "simplify")

- **Evidence:** F-4 / PO-12. The tempting one-liner
  `if isinstance(field, OneToOneField) and field.remote_field.parent_link:`
  drops lone non-parent-link OTOs from `parent_links`, which **breaks**
  `test_missing_parent_link` (the loop would auto-create `place_ptr` instead of
  raising `Add parent_link=True`).
- **Classification:** test-contract guard (would-be regression).
- **UltimatePowers question:** "Is the `Add parent_link=True` error on a lone
  non-parent OTO an intended part of the public contract?" → Yes (it has a
  dedicated test). So the fallback-to-last behaviour (I3) is **required**.
- **Recommended next change:** none. Retain the `existing is not None and
  existing.remote_field.parent_link and not field.remote_field.parent_link:
  continue` shape. (A positive-form rewrite `if existing is None or
  field…parent_link or not existing…parent_link: parent_links[...] = field` is
  logically identical, PO-7/PO-8; not worth the churn/regression risk.)
- **Tests:** keep `test_missing_parent_link`.

## G-2. Optional, separate hardening: a "multiple parent links" model check

- **Evidence:** F-7 / no PO closes it (out of scope). Two
  `parent_link=True` OTOs to the same parent are silently de-duplicated
  (last wins) by this loop — pre-existing, not introduced by V1.
- **Classification:** missing model-validation check (latent, pre-existing).
- **UltimatePowers question:** "Should declaring two `parent_link=True` fields to
  the same parent be a `models.E…` system-check error rather than silently
  picking one?"
- **Recommended next change:** **not** in this issue. If desired, add a
  `check()`-level error in a *separate* change (e.g. in
  `Model._check_*` / field checks), independent of the collection loop. Do not
  fold it into the selection fix.
- **Tests:** would need a *new* check test (out of scope; tests are frozen here).

## G-3. Optional, separate UX: enumerate candidates in the missing-parent error

- **Evidence:** F-6. When no parent link exists but several OTOs to the parent
  do, `Options._prepare` names only the *last* field (`Add parent_link=True to
  …Picking.b`).
- **Classification:** error-message UX (cosmetic), pre-existing.
- **UltimatePowers question:** "Should the error list all candidate OTOs so the
  user knows which to mark?"
- **Recommended next change:** none for this issue; a wording-only tweak in
  `options.py:255-257` if ever desired.

## G-4. Verification-tier follow-up (to upgrade *constructed* → *machine-checked*)

- **Evidence:** PROOF.md §5; PO-7/PO-8/PO-11/PO-14 marked `[ESC]`.
- **Classification:** proof-capability gap (bundled arithmetic tier vs.
  list-induction), **not** a code bug.
- **Recommended next change (verification only):** add `[simplification]`
  list-induction lemmas for `anyPL`, `candOf`, `lastF`, membership over
  `Fields`, then run `kompile`/`kprove` (PROOF.md §5) and confirm `#Top`. Route
  via `knowledge/sources.md` (reachability logic + μ-logic inductive predicates).
- **Tests:** only after `#Top` may the §8 redundant order-specific tests be
  considered for removal — **recommendation-only**, and moot here (test files are
  frozen).

---

## Summary table

| Item | Type | Action this pass |
|---|---|---|
| G-1 | regression guard | **keep V1 as-is** |
| G-2 | latent missing check (F-7) | defer — separate change |
| G-3 | error-message UX (F-6) | defer — separate change |
| G-4 | proof-tier gap | defer — verification follow-up |

**No code edits in `repo/` this pass.** The FVK artifacts justify "V1 stands."
