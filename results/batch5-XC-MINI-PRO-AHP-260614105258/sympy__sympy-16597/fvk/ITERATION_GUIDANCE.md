# ITERATION_GUIDANCE.md — sympy-16597

Feedback package for the next code/spec iteration. Derived from
[`FINDINGS.md`](FINDINGS.md) and [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md).

## Verdict on V1

**V1 stands — confirmed by the audit.** The single added production
`'rational -> finite'` (`assumptions.py:175`) discharges the intent obligations
PO1–PO3 and every safety obligation PO4–PO8/PO5-rt with no introduced defect. No
source edit is recommended in this pass. Rationale tracing in
[`../reports/fvk_notes.md`](../reports/fvk_notes.md).

## Decisions locked by this iteration

1. **Attach `finite` to `rational`, not to `real` or to `integer`.**
   - `real → finite` is *unsound here* (PO5/F6: extended-real `oo` is real ∧
     infinite → import crash). Rejected.
   - `integer → finite` alone would leave bare `Symbol(rational=True)` non-finite,
     contradicting "all rationals are finite" and the hint L3. Rejected.
   - `rational → finite` is the **maximal safe** choice and reaches integer/even/
     odd via the pre-existing chain. **Chosen.**
2. **Do not touch `irrational == real & !rational`** in this pass. Tightening it
   (e.g. `… & finite`) exceeds scope and risks the existing `irrational` tests;
   adding `irrational → finite` outright crashes `oo` (F2). Deferred to the
   redesign below.

## Open question for the next pass (UltimatePowers-style)

> **Q (the one real design gap, F6/F2):** Should SymPy distinguish `real`
> (finite real) from `extended_real` (real ∪ {±∞})? Concretely: should
> `oo.is_real` be `False` with a new `oo.is_extended_real = True`, so that
> `real → finite` becomes sound and `oo.is_irrational` resolves to `False`?

- **If yes (the principled fix):** introduce `extended_real`; relate
  `real == extended_real & finite`; re-home the infinities onto `extended_real`;
  then `real → finite` is consistent and the F2 `irrational` artifact disappears.
  This is a **large, breaking** change (the hint L4 explicitly flags it: "adding
  finite to real would probably break a lot of code"), so it is a *separate
  issue*, not part of fixing #16597.
- **If no / not now:** keep V1; accept `oo.is_irrational=True` as the documented,
  consistent consequence of the current `irrational` definition (F2).

The recommended near-term answer is **"not now"**: ship the minimal `rational →
finite` (V1) that fixes the reported bug, and track the `extended_real` redesign
separately.

## Recommended next code/spec changes (only if scope expands)

| Trigger | Change | Obligation it would add |
|---|---|---|
| Decide to close F6 | add `extended_real`; `real == extended_real & finite`; move `oo/-oo/zoo` to `extended_real` | new PO: `real → finite` consistent; `oo.is_irrational == False` |
| Audit infinite powers (F5) | give `Pow._eval_is_rational` an explicit `base.is_infinite` guard before the `is_irrational` branch | PO: `oo**e` rationality correct for symbolic `e` |
| Want machine-checking | run the §7 `kompile`/`kprove` commands in [`PROOF.md`](PROOF.md) | upgrades PO1–PO7 from *constructed* to *verified* |

## Tests

- **Add / keep (regression for this issue):** `Symbol(even=True).is_finite`,
  `Symbol(integer=True).is_finite`, `Symbol(rational=True).is_finite` all `True`.
- **Keep (pin the forced consequences):** the `oo`/`-oo`/`zoo`/`nan` assertion
  blocks (`is_rational`, `is_integer`, `is_irrational`, `is_noninteger`) — these
  are exactly where F2/F3 would regress. *In this benchmark the suite is fixed and
  hidden; do not modify it.*
- **No removals recommended** (Honesty gate: proof is constructed, not
  machine-checked).

## Residual-risk ledger (carry forward)

- `oo.is_irrational == True` (F2) — consistent, intent-divergent; resolved only by
  the `extended_real` redesign.
- `Pow` infinite-base rationality (F5) — pre-existing, edge-case, out of scope.
- Trusted base: mini-X adequacy + un-run `kprove` (PROOF §9).
