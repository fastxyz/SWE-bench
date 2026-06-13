# PROOF OBLIGATIONS — parent-link collection loop

Verification conditions (VCs) and side conditions generated while constructing
the proof of `(FOLD)` and `(SELECT-PL)` (see `fvk/PROOF.md`). Each is tagged with
a discharge tier:

- **[Z3]** — linear integer / boolean fact, bundled SMT tier.
- **[STRUCT]** — structural induction on the `Fields` list / map step; discharged
  by the claim's own circularity (guarded coinduction).
- **[ESC]** — `[ESCALATION BOUNDARY]`: an inductive‑list/map predicate VC that the
  bundled arithmetic tier does **not** machine-discharge. A complete hand proof is
  given in `fvk/PROOF.md`; machine-checking needs list-induction lemmas
  (`anyPL`/`candOf`/`lastF`), routed per `knowledge/sources.md`. **Never admitted
  as `[trusted]`.**

Each obligation links to the SPEC postcondition clause (I1/I2/I3/D) and/or the
FINDINGS entry it backs.

---

## A. Well-definedness / no-crash obligations

| # | Obligation | Tier | Notes |
|---|---|---|---|
| **PO-1** | `existing.remote_field.parent_link` never raises `AttributeError`. In the model: `plOf(M[K])` is read only when `K in_keys(M)`. | [Z3] | `skip/3` is defined by three rules whose `requires` make the `M[K]` read reachable only under `K in_keys(M)`; mirrors Python `and` short-circuit. Backs **F-1**. |
| **PO-2** | `existing` is always `None` or a `OneToOneField` (so it *has* `remote_field.parent_link`). | [STRUCT] | `parent_links` only ever stores `field(..)` values written from the `isinstance(field, OneToOneField)` branch; `<plinks>` holds only `Field`s by construction. Backs **F-1**. |
| **PO-3** | `skip/3` and `updateSel/2` are **total** (every `(M,K,PL)` / `(M,F)` reduces). | [Z3] | The three `skip` `requires` are exhaustive and pairwise exclusive: `¬(K∈M)` ∨ (`K∈M` ∧ `g`) ∨ (`K∈M` ∧ `¬g`) where `g ≡ plOf(M[K])=1 ∧ PL=0`. |

## B. (FOLD) — the loop computes the fold

| # | Obligation | Tier | Notes |
|---|---|---|---|
| **PO-4** | Base: `select(.Fields)` from `⟨plinks⟩ M` reaches `⟨plinks⟩ M`, and `foldSel(M,.Fields)=M`. | [Z3] | Rule `select(.Fields)=>.K`; `foldSel` base rule. |
| **PO-5** | Step/guardedness: `select(F;Rest)` makes one genuine `=>⁺` step to `select(Rest)` with `⟨plinks⟩ updateSel(M,F)`, and `foldSel(M,F;Rest)=foldSel(updateSel(M,F),Rest)`. | [STRUCT] | The single rule fires (guardedness satisfied); circularity invoked on `Rest`. Definitional match to `foldSel`'s cons rule. |

## C. (SELECT-PL) — selection correctness (per key), I1 ∧ I2 ∧ I3

Induction on the candidate list `FS = [f_1, … , f_m]` (all key `K`), folded from
the empty slot. Invariant **INV(t)** over the processed prefix `FS[1..t]`
(SPEC §4, restated in PROOF.md §3):
`chosen_t ∈ FS[1..t]` ∧ `chosen_t.PL=1 ⟺ anyPL(FS[1..t])` ∧
`(¬anyPL(FS[1..t]) ⇒ chosen_t = last(FS[1..t]))`.

| # | Obligation | Tier | Backs |
|---|---|---|---|
| **PO-6** | INV(1): after the first candidate, `chosen_1 = f_1` (slot empty ⇒ `¬skip`); I1/I2/I3 hold for `[f_1]`. | [Z3] | I1,I2,I3 |
| **PO-7** | Preservation, **skip** branch (`existing.PL=1 ∧ f_{t+1}.PL=0`): `chosen` unchanged; INV(t) ⇒ INV(t+1). Uses: existing already a parent link ⇒ `anyPL` unchanged true. | [ESC] | I2,I3 |
| **PO-8** | Preservation, **overwrite** branch (`existing.PL=0 ∨ f_{t+1}.PL=1`): `chosen_{t+1}=f_{t+1}`; INV(t) ⇒ INV(t+1). Critical sub-case: `f_{t+1}.PL=0 ∧ existing.PL=0` needs **¬anyPL(FS[1..t])**, obtained from INV(t)'s I2 *contrapositive* (`chosen_t.PL=0 ⇒ ¬anyPL`). | [ESC] | I1,I2,I3 |
| **PO-9** | Closure: INV(m) ⇒ I1 ∧ I2 ∧ I3 for the full `FS`. | [Z3] | I1,I2,I3 |
| **PO-10** | Biconditional collapse `plOf(chosen)==1 ==Bool anyPL(FS)` is well-typed given `PL ∈ {0,1}`. | [Z3] | I2 |

> **Why PO-7/PO-8 are [ESC].** They quantify over `anyPL`/`last`/`∈` on a
> symbolic list — inductive predicates the bundled `[simplification]` tier (linear
> arithmetic + map extensionality) does not close mechanically. The *logic* is
> elementary (a 2-line case split) and fully discharged by hand in PROOF.md §3;
> only the *machine* check is deferred. This is the honest insertion-sort-style
> posture: claims stated, hand-proved, the inductive VCs named — not faked.

## D. (KEY-INDEP) — lifting single-key to the interleaved full list

| # | Obligation | Tier | Backs |
|---|---|---|---|
| **PO-11** | For `K' ≠ K`, `updateSel(M, field(K',·,·))` does not change `M[K]`; hence the subsequence of non-`K` visits never perturbs key `K`. So `foldSel(.Map, VS)[K] = foldSel(.Map, candOf(VS,K))[K]`. | [ESC] | D, I1–I3 lift |
| **PO-12** | Domain: `K ∈ keys(foldSel(.Map,VS)) ⟺ K ∈ keysOf(VS)`. First visit of any key takes the `¬skip` (empty-slot) branch, so every visited key is inserted and no other key is. | [STRUCT]/[Z3] | **D** (preserves `test_missing_parent_link`) |

## E. Differential obligation vs. the original code (regression guard)

| # | Obligation | Tier | Backs |
|---|---|---|---|
| **PO-13** | `keysOf`-domain of `parent_links` is **identical** to the pre-fix code (which did unconditional `parent_links[K]=field`). Both insert exactly the visited keys; V1 only ever differs in the *value* at a key, never its presence. | [Z3]/[STRUCT] | **D**, F-3 |
| **PO-14** | On every input where the original code already satisfied I2 (parent-link field was last, or ≤1 candidate per key), V1 yields the **same** map. I.e. V1 is a conservative extension: it changes output *only* on the buggy inputs. | [ESC] | F-3 |

---

## Discharge summary

- **[Z3] / [STRUCT]:** PO-1..PO-6, PO-9, PO-10, PO-12, PO-13 — bounded, linear,
  or definitional; constructed and expected `#Top` under `kprove` once the
  fragment is `kompile`d.
- **[ESC]:** PO-7, PO-8, PO-11, PO-14 — list-inductive; **hand-proved complete**
  in `fvk/PROOF.md` §3–§4, machine check deferred to list-induction lemmas.

No obligation is unmet *logically*. The only gap is machine-checking the
list-inductive VCs — a **capability** gap of the bundled tier, **not** a
correctness gap in the fix. Conclusion feeds `fvk/PROOF.md` and the
"V1 stands" decision in `reports/fvk_notes.md`.
