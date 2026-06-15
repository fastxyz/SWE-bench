# ITERATION_GUIDANCE.md — next-pass feedback for #13852

What the FVK audit concluded, and what a subsequent code/intent pass should do.

## Verdict: V1 stands (no code change in this FVK pass)

The audit found **no defect** in V1's two changes. Every `pass` obligation
(PO-1…PO-4, PO-7) is met and the spec was clean to write for the changed branches
— a positive signal the fix is well-targeted (FINDINGS F-CONFIRM-1…5). The
adequacy round-trip (PROOF.md §B/§C) shows the K claims' English matches the public
intent (I1–I3, I5) with no `fail`. Therefore **V2 == V1**, justified by the
artifacts — *not* by any SUSPECT test, pre-fix display, or dropped-on-scope change:

- The SUSPECT legacy test (F4) is treated as a positive bug signal, not preserved.
- The one named-and-not-applied change (golden-ratio values, F2) was **promoted to
  a tested hypothesis** (PROOF.md §A3, derived & triple-checked) and rejected for
  V1 on **positive feasibility/correctness grounds** (no canonical argument form ⇒
  dead-code risk), with the derivation preserved — not waved off as "out of scope."

## Why no change rather than "add more special values"

Per "derive, don't guess" + "construct ≠ withhold":
- `Li₂(1/2)` — clean argument (`S.Half`) **and** clean value ⇒ applied (V1). ✓
- `Li₂(2)` — clean argument, **branch-cut-dependent value sign** ⇒ cannot derive
  confidently ⇒ Finding F1, not code.
- golden-ratio ×4 — **values derived** (triple-checked) but **arguments
  non-canonical** ⇒ literal guards risk un-confirmable dead code ⇒ Finding F2 with
  values ready, not code.
- `Li_n(1/2)`, n≥3 — different function, coefficient uncertainty ⇒ Finding F3.

Adding fragile, possibly-dead matching code would introduce a new correctness
surface and contradict the minimal-bug-fix goal; the honest move is to record the
derived values for a properly-designed follow-up.

## Concrete next steps (future passes, beyond this issue)

1. **Resolve UltimatePowers Q1** (FINDINGS): decide whether dilog special values
   should auto-evaluate in `eval` or stay `expand_func`-only. Current evidence →
   `expand_func` only (the issue's transform form). If product owners want bare
   auto-eval, relocate branch 3's value into `eval` and update F5.
2. **Implement F2 properly:** add golden-ratio recognition with an explicit
   canonicalization step (normalize `(sqrt(5)±1)/2`, `S.GoldenRatio`-based forms to
   one representative) and a representation test matrix; drop in the four §A3
   values. Gate behind a derivation comment + the reflection/Landen/duplication
   cross-checks.
3. **Resolve F1:** confirm `mpmath.polylog(2, 2)`'s imaginary-part sign, then add
   `Li₂(2)` (or deliberately keep symbolic per a branch-cut policy).
4. **Consider F3:** a separate "higher polylog special values" enhancement
   (`Li₃(1/2)`, …) with verified coefficients.
5. **Run the machine check:** execute the PROOF.md §E `kompile`/`kprove` commands
   to upgrade the proof from *constructed* to *machine-verified*; only then act on
   any test-redundancy recommendation.

## Tests (recommendation-only)

No removals recommended. Expect the hidden suite to assert the corrected forms
(`expand_func(polylog(1,z)) == -log(1-z)`, `expand_func(polylog(2,S.Half)) ==
-log(2)**2/2 + pi**2/12`); the SUSPECT test (F4) at `test_zeta_functions.py:131`
should be updated upstream — we neither edit nor delete it.
