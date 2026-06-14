# ITERATION GUIDANCE — `polylog._eval_expand_func` (sympy__sympy-13852)

Feedback package for the *next* code/spec generation pass. Each item names its
origin (a FINDINGS or PROOF_OBLIGATIONS entry), a classification, the
UltimatePowers-style question the intent layer should ask, and the concrete next
change (if any). Per the FVK loop, `/verify` does **not** silently regenerate code;
this file is the accumulated evidence so a human or a later pass can act.

---

## Verdict on this iteration

**V1 is confirmed correct; the only change in V2 is two inert clarifying comments.**
The dispatch spec was clean (no spec-difficulty bug signal), all STRUCT/Z3
obligations discharged, and the two analytic obligations discharged at the
escalation tier with cited identities + numerical witnesses. There is **no
correctness defect to repair**.

---

## G1 — Machine-check the dispatch (close the "constructed, not checked" gap)
- **Origin:** PROOF.md §5; honesty gate.
- **Classification:** proof capability gap (kit MVP does not run the toolchain).
- **Question:** "Do you want the dispatch claims actually discharged by `kprove`
  (`#Top`) before relying on the test-redundancy recommendation?"
- **Next change:** emit `polylog-expand.k` / `polylog-expand-spec.k` as standalone
  files and run the §5 commands. Expect `#Top` on the five dispatch claims +
  the Euler-loop circularity. No code change.

## G2 — Discharge VC-Li1 / VC-Li2½ with a CAS-identity oracle
- **Origin:** PROOF.md §3; Finding PF1; PO1/PO2 (⛰).
- **Classification:** proof capability gap (special-function identities exceed the
  bundled Z3 / `[simplification]` arithmetic tier).
- **Question:** "Should branch-cut equality of `-log(1-z)` vs mpmath
  `polylog(1,z)` on `[1,∞)` be certified (the `Im=-pi` agreement), rather than
  trusted from sampling?"
- **Next change:** route to a dilogarithm/branch-cut identity checker (e.g. a
  certified reflection-formula derivation for `Li_2(1/2)`, and an interval/branch
  argument for `Li_1`). Until then they stay at the escalation tier — **not**
  `[trusted]`. No code change.

## G3 — (enhancement, NOT required) generalize the special-value table
- **Origin:** Finding F8; ledger L1.
- **Classification:** underspecified intent / scope question (not a bug).
- **Question:** "Is `Li_2(1/2)` the only special value wanted, or should
  `expand_func` also evaluate other closed-form dilog/polylog points (e.g.
  `Li_2` at golden-ratio arguments, or a general `s`-at-roots-of-unity table)?"
- **Next change:** *only if intent expands.* The current issue asks for exactly
  one value; adding more now would be unprompted scope creep and risks new
  doctest/test churn. Recorded, deliberately **not** implemented.

## G4 — (enhancement, NOT required) float vs Rational policy for the ½ guard
- **Origin:** Finding F7.
- **Classification:** intent clarification (benign behavior).
- **Question:** "Should `polylog(2, 0.5)` (a float) also collapse to the exact
  `pi**2/12 - log(2)**2/2`, or stay numeric/unevaluated?"
- **Next change:** none recommended. `Float(0.5) == S.Half` is `True` and the exact
  value is a reasonable answer; adding `and z.is_Rational` would reject a value that
  *is* `1/2`. Leave as-is unless intent says floats must stay numeric.

## G5 — Update the visible test that pins the old `exp_polar` form
- **Origin:** Finding F9; ledger L3.
- **Classification:** test gap / housekeeping (the behavioral change is intended).
- **Question:** none (intent is unambiguous from the issue).
- **Next change (test-side, for whoever lands the fix — I must not edit tests):**
  `test_zeta_functions.py:131` should become
  `assert myexpand(polylog(1, z), -log(1 - z))`, and a line such as
  `assert myexpand(polylog(2, S.Half), -log(2)**2/2 + pi**2/12)` should be added.
  The source-side doctest copies of these were already updated in V1/V2.

---

## Tests to add / keep / (conditionally) remove

- **ADD (test-side):** `expand_func(polylog(2, S.Half)) == -log(2)**2/2 + pi**2/12`;
  update the `polylog(1, z)` assertion to `-log(1 - z)`; optionally a
  derivative-consistency assertion `expand_func(diff(polylog(1, z) + log(1 - z),
  z)) == 0` (pins PO4 directly).
- **KEEP:** the `s≤0` rational-function tests, `test_derivatives`,
  `test_lerchphi_expansion`, and the `hyperexpand` polylog lines (integration /
  out-of-unit-contract / loop-coverage). See PROOF.md §6.
- **CONDITIONALLY REMOVE (only after `kprove` `#Top` + CAS-identity check):** the
  two single-point `expand_func` asserts subsumed by (EXPAND-S1)+VC-Li1 and
  (EXPAND-HALF)+VC-Li2½. CI saving is negligible; default recommendation is to keep
  them.

---

## One-line status

No code defect found; V1's behavior stands. Open items are *kit-capability*
upgrades (G1, G2) and *optional intent* questions (G3, G4) — none blocks correctness
of the audited fix.
