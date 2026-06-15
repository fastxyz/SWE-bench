# reports/fvk_notes.md — FVK audit of the #13852 fix

Outcome: **V1 stands unchanged.** The FVK audit confirmed both V1 changes are
correct and surfaced no defect in them; the only open items are *additional*
dilogarithm-family members, recorded as Findings with derivations rather than
implemented, on positive feasibility/correctness grounds. Every decision below is
traced to specific entries in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

The source code in `repo/` is therefore **byte-for-byte identical to V1**. No edit
was applied in this pass, because the audit justified confirmation, not revision.

---

## Decision 1 — Keep `polylog(1, z) → -log(1 - z)` (drop exp_polar)
**Trace:** PO-1 (MET), PO-2 (MET); FINDINGS F-CONFIRM-1, F-CONFIRM-2.
**Why:** Adequacy §A1 proves `Li₁(z) ≡ -log(1-z)` including the branch cut (Im = −π
for z>1), matching the issue's claim and mpmath. The adversarial reproduction
(F-CONFIRM-1) shows V0's `return -log(1 + exp_polar(-I*pi)*z)` injects `exp_polar`
at exactly that line, and V1 removes it at the source; derivative consistency
(PO-2) then collapses to `0`. The library's own `hyperexpand` emits `-log(1-z)`
(`test_hyperexpand.py:582`, ledger L9), independent positive evidence for the form.
No change needed.

## Decision 2 — Keep `Li₂(1/2) → -log(2)**2/2 + pi**2/12`
**Trace:** PO-3 (MET); FINDINGS F-CONFIRM-3; SPEC §3 row `1/2`.
**Why:** Adequacy §A2 re-derives the value from Euler's reflection law (numeric
check ≈ 0.5822). The argument `S.Half` is SymPy's unique canonical `1/2`, so the
guard `z == S.Half` is guaranteed to fire — clean value *and* clean
implementation. No change needed.

## Decision 3 — Keep the value on the `expand_func` path, not `eval`
**Trace:** Intent I3; FINDINGS F-CONFIRM-4, F5.
**Why:** The answer is shown under `.expand(func=True)` (issue In[2]), so by the
output-form rule (intent-evidence.md §3) the obligation binds on the transform
path. I explicitly did **not** enshrine "stays unevaluated in eval" as an invariant
(the formalize.md §42 warning names this very issue) — F5 records the bare
`polylog(2, 1/2)` staying symbolic as an *intentional, audited* choice, not a
silent one. I also did **not** blindly invert it into `eval`: that would be
inconsistent with the sibling `s`-specific reductions (`s==1`, `s≤0`), which all
live in `_eval_expand_func`, whereas `eval` holds only the z-based, all-`s`
reductions `z∈{0,1,-1}`. Placement decided by positive evidence, both directions
considered. No change.

## Decision 4 — Do NOT add golden-ratio dilogarithm values (defer, with derivation)
**Trace:** PO-6 (DEFERRED); FINDINGS F2; PROOF §A3; SPEC §3 golden-ratio rows.
**Why (positive grounds, not "scope"):** Per verify.md Step 3, I promoted this
named change to a tested hypothesis: the four values were **derived and
triple-checked** (reflection ⊕ Landen ⊕ duplication all consistent, PROOF §A3) —
so they are *not guessed*. They are still deferred because the **arguments have no
canonical SymPy form**: I verified in-repo that `S.GoldenRatio` (a singleton),
`(sqrt(5)-1)/2`, and `1/S.GoldenRatio` are distinct objects, so a literal
`z == (sqrt(5)-1)/2` guard would silently miss most spellings — un-confirmable as
live code without execution, and a half-measure if added. Implementing it properly
needs an argument-canonicalization step the issue neither specifies nor
demonstrates, with its own correctness surface. The derived values are preserved in
F2 ready to drop in once that recognition layer exists. This is "derive → record →
recommend," not a scope dodge.

## Decision 5 — Do NOT add `Li₂(2)` (defer)
**Trace:** PO-6 (DEFERRED); FINDINGS F1; PROOF §A4; SPEC §3 row `2`.
**Why:** The argument `z=2` is clean, but `2` lies **on** the branch cut `[1,∞)`,
so `Im(Li₂(2)) = ±π·log 2` depends on the approach direction. I cannot derive the
sign without confirming mpmath's convention — and the issue's Part 2 is precisely
about getting branch behavior right, so a guessed sign would be the wrong kind of
fix. "Never guess a value you cannot derive" ⇒ Finding, no code.

## Decision 6 — Do NOT add `Li_n(1/2)` for n≥3 (defer)
**Trace:** PO-6 (DEFERRED); FINDINGS F3; SPEC §3 note.
**Why:** `Li₃(1/2)` etc. belong to a *different* function (trilogarithm), outside
the dilogarithm family the issue's single example exhibits, and the coefficients
(7/8, 1/12, 1/6) carry memory-uncertainty here. Out of family + not confidently
derivable ⇒ Finding, no code.

## Decision 7 — Do NOT edit the SUSPECT legacy test
**Trace:** FINDINGS F4; ledger L8.
**Why:** `test_zeta_functions.py:131` asserts the old `-log(1 + exp_polar(-I*pi)*z)`
form the issue calls "not meaningful." Per the SUSPECT rule it encodes the reported
bug, so its existence is a *positive bug signal* consistent with the fix — **not** a
reason to keep V1's old behavior. The task forbids editing tests and the suite is
fixed/hidden; the corrected assertion `-log(1 - z)` is expected upstream. I did not
let this test veto the intent, and I did not touch it.

## Decision 8 — Keep the docstring doctest update
**Trace:** ledger L6; PROOF §D (compat table).
**Why:** The class docstring's `>>> expand_func(polylog(1, z))` example is owned by
the source file (not a test file) and must reflect the new output `-log(-z + 1)`
(SymPy prints `1 - z` as `-z + 1`, matching the adjacent `z/(-z + 1)` doctest). V1
already updated it; kept.

## Decision 9 — Confirm public compatibility (no API/dispatch change)
**Trace:** PO-7 (MET); FINDINGS F-CONFIRM-5; PROOF §D.
**Why:** No signature/return-shape/dispatch change. `lerchphi._eval_expand_func`
calls `polylog(...)._eval_expand_func` only with symbolic `s` in tested cases ⇒
branches 1/3 never fire ⇒ identical output; `hyperexpand` uses `s=3`/symbolic-`z`
polylogs ⇒ untouched; `fdiff`/the `diff` docstring rule are unchanged. No unhandled
callsite or override.

## Decision 10 — No cosmetic refactor of branch order
**Trace:** PO-3, PO-4 (both MET); no Finding raised against placement.
**Why:** The dilog check sits after the `s≤0` branch, but `s=2` and `s≤0` are
disjoint so dispatch is unaffected (PROOF §C-proofs show branch 3 fires iff
`s=2 ∧ z=½`). The audit surfaced no problem, so per the minimal-change directive I
left the code exactly as V1 rather than make an unjustified edit.

---

## Soundness vs. completeness (honest framing)
The constructed proof (PROOF.md, *constructed, not machine-checked*) establishes
that V1's **changes are correct** (PO-1…PO-4, PO-7). It does **not** claim the
dilogarithm family is **complete**: `Li₂(2)`, the golden-ratio values, and
`Li_n(1/2)` are *un-audited remainder* (F1–F3), recorded with derivations, not
proven. A green proof of the V1 claims is *necessary and sufficient* for accepting
this minimal bug-fix (it fixes exactly the two reported defects, correctly), while
the deferred members are explicit next-iteration work in
[`fvk/ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md). The `V2 == V1`
conclusion rests on the positive `pass` rows of SPEC_AUDIT, never on a SUSPECT
test, a pre-fix display, or a change dropped on scope grounds.
