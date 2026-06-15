# PROOF_OBLIGATIONS.md — `polylog._eval_expand_func` (issue #13852)

Each obligation is `phi_pre ⇒ phi_post` against [`mini-python.k`](mini-python.k),
with the **adequacy** side (is the produced term the mathematically correct
value?) split out explicitly, because K dispatch-soundness ≠ mathematical
correctness of the value. Status legend: **MET** (V1 discharges it), **DEFERRED**
(derived but not implemented, with reason), **TRUSTED** (inherited from existing
tests / outside the bundled tier).

---

## PO-1 — Branch 1 dispatch (claim POLYLOG-S1)
- **pre:** `expandPL(polylog(1, Z))`, `Z` a symbolic Expr.
- **post:** `=> neg(logE(sub(1, Z)))`  i.e. `-log(1 - z)`.
- **adequacy:** `-log(1-z)` is the correct value of `Li₁(z)` (PROOF.md §A1:
  power series for |z|<1 + identical branch cut on [1,∞), Im = −π for z>1).
- **negative obligation:** the post-term contains **no** `expPolar` symbol.
- **traces:** I1, I2, L2, L3, L4. **Status: MET.**

## PO-2 — Branch 1 derivative consistency
- **pre:** `expand_func(diff(polylog(1,z) + log(1-z), z))`.
- **post:** `=> 0`.
- **derivation:** `diff(polylog(1,z),z) = polylog(0,z)/z` (fdiff, unchanged);
  branch 2 at `s=0` gives `polylog(0,z) → z/(1-z)`, so the term is
  `(z/(1-z))/z − 1/(1-z) = 0`. Depends on PO-1 form + branch-2(s=0).
- **traces:** I2, L4. **Status: MET** (follows from PO-1 ∧ PO-5).

## PO-3 — Branch 3 dispatch (claim POLYLOG-DILOG-HALF)
- **pre:** `expandPL(polylog(2, half))`.
- **post:** `=> add(neg(divE(powE(logE(2),2),2)), divE(powE(piC,2),12))`
  i.e. `-log(2)**2/2 + pi**2/12`.
- **adequacy:** equals `Li₂(1/2)` by the reflection law (PROOF.md §A2):
  `2·Li₂(½) = π²/6 − log²(½) = π²/6 − log²2 ⇒ Li₂(½) = π²/12 − log²2/2`.
  Numeric cross-check ≈ 0.5822.
- **placement obligation:** must hold on the `expand_func` path (value shown
  under `.expand(func=True)` in In[2]); V1 places it in `_eval_expand_func`. ✓
- **traces:** I3, L1. **Status: MET.**

## PO-4 — Branch 4 no over-fire (claims POLYLOG-DEFAULT, POLYLOG-DILOG-NONHALF)
- **pre:** `expandPL(polylog(3, z))` and `expandPL(polylog(2, z))`, `z` symbolic.
- **post:** `=> polylog(3, z)` and `=> polylog(2, z)` (unchanged).
- **purpose:** the added branch 3 fires **only** at `s=2 ∧ z=½`; other orders and
  symbolic `z` are untouched (targeted-fix / regression obligation).
- **traces:** I5, L9. **Status: MET** (mutually-exclusive guards + `[owise]`).

## PO-5 — Branch 2 loop (claim LOOP)
- **pre:** `iterD(N, T)`, `N = −s ≥ 0`.
- **post:** `=> applyDn(N, T)` — applies `applyD` exactly N times; terminates.
- **circularity:** coinduction on `N` (base `N=0`; step invokes the claim on
  `(N−1, applyD(T))` + commutation `applyDn(K, applyD(T)) = applyD(applyDn(K,T))`).
- **adequacy (mathematical):** `applyD = u·d/du`, and
  `(u·d/du)^N[u/(1−u)]|_{u=z} = Li_{−N}(z)` — number-theoretic, **inherited**
  from `test_polylog_expansion` (`polylog(0,z)→z/(1-z)`, `polylog(-1,z)→…`).
- **traces:** L (branch 2). **Status: TRUSTED** (loop structure MET; differentiation
  semantics out of bundled K tier → trusted base, unchanged by the fix).

## PO-6 — Family completeness (obligation I4)
- **pre:** the dilogarithm special-value table (SPEC §3).
- **post:** every *derivable* member is applied; every non-derivable member is an
  open Finding with its derivation status.
- **status by member:**
  - `0,1,-1` — **MET** (pre-existing `eval`).
  - `1/2` — **MET** (PO-3).
  - `2` — **DEFERRED** (F1): value's imaginary-part sign branch-cut-dependent, not
    confidently derivable.
  - golden-ratio ×4 — **DEFERRED** (F2): values derived & triple-checked, but
    argument has no canonical SymPy form ⇒ implementation risks dead code; deferred
    on positive feasibility grounds, derivations preserved.
  - `Li_n(1/2), n≥3` — **DEFERRED** (F3): outside the dilogarithm family the example
    exhibits; coefficient uncertainty.
- **note:** DEFERRED ≠ proven correct. These are *un-audited remainder* of the
  intent, recorded as Findings, not folded into a "fix is complete" claim
  (verify.md Step 1 soundness≠completeness).

## PO-7 — Public compatibility (no API/signature change)
- **pre:** every public caller / override of `polylog` expansion.
- **post:** unchanged dispatch shape; the only changed observable is the *value*
  returned for `s=1` (intentional, I1) and `s=2,z=½` (intentional, I3).
- **callsites:** `lerchphi._eval_expand_func` (symbolic `s` ⇒ unaffected);
  `hyperexpand` (produces `-log(1-z)` itself, `s=3` polylogs untouched).
- **traces:** I5. **Status: MET.** Full table: PROOF.md §D.

---

## Discharge summary

| Obligation | Discharges | Status |
|---|---|---|
| PO-1 | I1, I2, L2–L4 | MET |
| PO-2 | I2, L4 | MET (← PO-1 ∧ PO-5) |
| PO-3 | I3, L1 | MET |
| PO-4 | I5, L9 | MET |
| PO-5 | branch-2 loop | TRUSTED (structure MET) |
| PO-6 | I4 family | `1/2` MET; F1–F3 DEFERRED |
| PO-7 | I5 compat | MET |

All MET obligations are **constructed, not machine-checked** (kprove not run).
No obligation is **failed**. The only open items are the DEFERRED family members
(PO-6), tracked as Findings F1–F3 with derivations.
