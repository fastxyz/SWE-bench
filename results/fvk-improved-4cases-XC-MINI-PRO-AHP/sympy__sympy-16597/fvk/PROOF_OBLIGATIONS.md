# PROOF_OBLIGATIONS.md — sympy__sympy-16597

Discharge obligations for the V1 fix `'rational -> real & finite'`. Each maps to
a claim in [`assume-spec.k`](assume-spec.k) and an intent-ledger entry in
[`SPEC.md`](SPEC.md). Closure semantics: [`mini-assume.k`](mini-assume.k).

| ID | Obligation (closure of `_assume_rules` after the fix) | Source | Claim | Status |
|----|--------------------------------------------------------|--------|-------|--------|
| **PO1** | `{even:True}` ⊢ `finite:True` | I1/E1 | (EVEN-FINITE) | discharged (PROOF §1) |
| **PO2** | `{integer:True}` ⊢ `finite:True` | I2/E2 | (INTEGER-FINITE) | discharged (PROOF §1) |
| **PO3** | `{rational:True}` ⊢ `real:True ∧ finite:True` | I3/E3/E4 | (RATIONAL-FINITE) | discharged (PROOF §1) |
| **PO4** | `{positive:True, infinite:True}` closes to a fixpoint **without** `#inconsistent`, with `finite:False, rational:False, integer:False, even:False, odd:False` | I5/E6 | (OO-CONSISTENT) | discharged (PROOF §2) |
| **PO5** | Termination: the closure halts on every input (no infinite deduction) | default-domain (I5) | — (meta) | discharged (PROOF §3) |
| **PO6** | No existing class raises `InconsistentAssumptions` at import under the new rule | I5/E6 | (OO-CONSISTENT)+(CLASH-DETECTED)+audit | discharged (PROOF §2, §5; SPEC §6) |
| **PO7** | Rejected-alternative soundness: adding `finite` to `real` or to `complex` forces an infinite singleton to `finite:True` ⇒ `#inconsistent`; hence the fix must attach `finite` to `rational` (which `oo`/`zoo` are *not*) | I4/E5/E6 | (CLASH-DETECTED) | discharged (PROOF §4) |
| **PO8** | Definition-faithfulness: deductions on `oo` (incl. `irrational:True`, `noninteger:True`) follow from the **unchanged** definitions `irrational == real & !rational`, `noninteger == real & !integer` and the pre-existing `oo.is_real=True`; nothing contradicts the glossary | I6/E7 | (OO-CONSISTENT) | discharged (PROOF §2, §4; FINDINGS F1) |

## Adequacy gate (must pass before trusting the proof)

- **AG1** `INTENT_SPEC`, `PUBLIC_EVIDENCE_LEDGER`, `FORMAL_SPEC_ENGLISH`,
  `SPEC_AUDIT`, `PUBLIC_COMPATIBILITY_AUDIT` present and non-empty — yes
  (`SPEC.md` §1, §2, §4, §5, §6).
- **AG2** `FORMAL_SPEC_ENGLISH` ⊆ `INTENT_SPEC` (no stronger/weaker) — yes;
  `SPEC_AUDIT` all-pass.
- **AG3** No claim's expected value rests only on the candidate patch or on a
  SUSPECT legacy test. The single under-determined value (`oo.is_irrational`, F1)
  is **not** used to justify `V2 == V1`; the no-change verdict rests on
  PO1–PO8 + positive rejection of alternatives B (F1) and the `floor` change
  (F4), per `intent-evidence.md` §5.8.

## Out-of-scope obligations (recorded, not discharged here)

- **OB1 (F4)** `floor(Symbol(real,infinite)).is_integer/.is_finite`
  order-dependence — pre-existing `floor` imprecision; no intent evidence.
- **OB2 (F5)** `Symbol('x', irrational=True).is_finite` stays `None` — blocked by
  the deliberately-retained extended-real meaning of `real` (I4).

Both are logged as Findings with a falsified-hypothesis rationale; neither is a
defect in V1 nor required by the issue intent.
