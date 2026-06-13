# reports/fvk_notes.md — FVK audit outcome for django__django-11400

## Verdict: **V1 stands, unchanged.**

The Formal Verification Kit audit (`/formalize` → `/verify`) confirmed the V1 fix is
correct and minimal. No source file was modified in this pass. This note justifies that
decision by tracing each V1 change — and each decision *not* to change anything — to
specific entries in `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`.

## What the audit did

I built a faithful "mini-X" K semantics (`fvk/mini_orm.k`) of the **only** queryset
state the fix turns on — `qs(order_by, default_ordering, Meta.ordering)` — with every
rule citing the Django source it mirrors (`sql/query.py`, `sql/compiler.py`,
`query.py`, `manager.py`, the two `get_choices`). I wrote function contracts as
reachability claims (`fvk/mini_orm-spec.k`) and constructed their proofs
(`fvk/PROOF.md`). Because each patched method is straight-line and the result
comprehension is a pure order-preserving map, **no loop circularity was needed**
(`SPEC.md` note L1) — the proofs are finite symbolic-execution chains.

The decisive, non-obvious fact the formalization flushed out (and the reason the
original #29835 code was wrong): **a bare `qs.order_by()` is not a no-op — it sets
`default_ordering = False`** (`query.py:1858-1881`), which makes the compiler ladder
(`compiler.py:262-273`) emit the empty explicit ordering and thereby *suppress*
`Meta.ordering`. Not calling `order_by` at all preserves `Meta.ordering`. This is
`FINDINGS.md` F1/F8, proved as claim **(BUG-OLD)** in `PROOF.md §2`.

## Per-change justification (each V1 edit is confirmed correct)

### M1 — `Field.get_choices`: guard `order_by` with `if ordering:`  → **KEEP**
- **Resolves** `FINDINGS.md` **F1** (root cause: `order_by(*())` suppressed `Meta.ordering`).
- **Discharges** `PROOF_OBLIGATIONS.md` **PO2** (empty ordering ⇒ `Meta.ordering`, proof §1)
  and **PO1** (non-empty ordering honored, proof §3).
- **Necessity** shown by **PO7 / (BUG-OLD)**: the pre-fix unconditional `order_by`
  provably violated PO2 (proof §2). So this guard is load-bearing, not cosmetic.
- **No regression**: **PO13/F6** — for non-empty `ordering` the call is byte-for-byte the
  old `order_by(*ordering)`; only the empty case changes. **PO12/F4** — the other
  `get_choices` callers (`formfield`, `formfield_for_choice_field`) take the
  `self.choices is not None` early-return *before* this code, so they are untouched.
  **PO14/F7** — models with no `Meta.ordering` stay unordered (no invented ordering).

### M2 — `ForeignObjectRel.get_choices`: same `if ordering:` guard  → **KEEP**
- **Discharges** **PO3** (reverse relations get the same contract, proof §4). Required
  because `RelatedFieldListFilter` reaches this method for reverse relations
  (`reverse_related.py` docstring). Same F1 root cause, same resolution.

### M3 — `field_admin_ordering` helper + `RelatedFieldListFilter.field_choices`  → **KEEP**
- **Discharges** **PO4** (admin ordering honored when present) and **PO5** (fallback to
  `Meta.ordering` with no/empty admin), proof §5.
- **Correctness of *which* model is ordered**: `FINDINGS.md` **F3 / PO11** — the helper
  consults the admin for `field.remote_field.model`, which I verified equals the model
  `get_choices` enumerates in *both* forward (`self.remote_field.model`) and reverse
  (`self.related_model = self.field.model`, since `ForeignObjectRel.remote_field =
  self.field`) directions. The helper is a pure refactor of the original lookup, so it
  introduces no new field-type assumption beyond what `RelatedFieldListFilter.__init__`
  already required.

### M4 — `RelatedOnlyFieldListFilter.field_choices`: thread `ordering=` through  → **KEEP**
- **Resolves** `FINDINGS.md` **F2** (this filter previously never ordered at all).
- **Discharges** **PO6**: it now reduces to the same `fieldChoicesOrdering` contract as
  M3 (the extra `limit_choices_to` is invisible to the ordering algebra, PO10), on the
  forward-relation domain D2 (proof §5).

## Decisions to NOT change anything (also traced)

- **Did not "fix" F5/PO16** (`RelatedOnlyFieldListFilter` + reverse relation →
  `TypeError`, because `ForeignObjectRel.get_choices` lacks `limit_choices_to`). This is
  **pre-existing**, untouched by the fix, and outside the issue. Recorded in
  `ITERATION_GUIDANCE.md §3` with the exact follow-up should the project want it.
  Touching it would violate the "minimal, on-issue" constraint.
- **Did not adopt the `filters.py`-only fallback (Alt-A)**, the `add_ordering` change
  (Alt-B), or a `RelatedOnly`-only fix (Alt-C) — all rejected in
  `ITERATION_GUIDANCE.md §4`. Alt-A in particular re-introduces the bare-`order_by()`
  trap and must be duplicated across forward/reverse; M1+M2 fix the root cause once
  where it lives.
- **Did not add an explicit `Meta.ordering` lookup** in the filters. By F8/PO9, letting
  `get_choices` simply *not call* `order_by` makes the queryset's existing
  default-ordering mechanism supply `Meta.ordering` — cleaner and semantically correct
  (`ordering=()` now genuinely means "no explicit ordering" rather than "force none").

## Residual risk (carried, not blocking)

1. **Trusted base** (`SPEC.md §4`, PO8/PO9): the proof transfers to the real code iff
   `mini_orm.k` faithfully models `query.py`/`compiler.py`. I read those lines directly;
   the abstraction of an ordering tuple to one empty/non-empty bit is sound because that
   is the only distinction either the code or the compiler ladder makes (F6, F8).
2. **Constructed, not machine-checked** (FVK MVP). To upgrade: `kompile mini_orm.k
   --backend haskell` then `kprove mini_orm-spec.k` (expect `#Top`). Per the Honesty
   gate, the test-redundancy suggestions in `PROOF.md §8` are recommendation-only and
   all tests should be kept until that check passes.
3. **Partial correctness** (PO15): comprehension termination is assumed (finite
   queryset), not proved.

## Bottom line

All correctness obligations PO1–PO7 are discharged by construction; all trusted-base
obligations PO8–PO12 by direct source citation; no-harm obligations PO13–PO14 by
inspection. The audit found **no correctness defect** in V1, and the one latent issue it
did surface (F5) is pre-existing and out of scope. **V1 is confirmed and stands
unchanged.**
