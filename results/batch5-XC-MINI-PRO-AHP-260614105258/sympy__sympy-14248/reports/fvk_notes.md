# reports/fvk_notes.md — FVK audit of the sympy-14248 fix

This explains every decision made during the FVK pass, tracing each to specific
entries in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md). The FVK artifacts are
the mini-X semantics [`fvk/matprint.k`](../fvk/matprint.k), the claims
[`fvk/matprint-spec.k`](../fvk/matprint-spec.k), and the five reports
[`SPEC.md`](../fvk/SPEC.md) / [`FINDINGS.md`](../fvk/FINDINGS.md) /
[`PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md) / [`PROOF.md`](../fvk/PROOF.md) /
[`ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md).

---

## Summary

The formalization confirmed V1 is correct on the issue's domain (the prompt's
"print like `a-b`" obligation), and surfaced **one genuine defect**: a totality
regression in `str._print_MatMul` for non-real numeric coefficients. I made
**exactly one source edit** to fix it and **kept the other four methods
unchanged**, with each non-change justified by the obligations/findings below.

---

## Change 1 (applied): `str.StrPrinter._print_MatMul`

**Edit:** `if c.is_number and c < 0:` → `if c.is_number and c.is_negative:`
(with an explanatory comment), in `repo/sympy/printing/str.py`.

**Traces to:** FINDING **F1**; obligation **PO-MM-TOTAL** (the *only* obligation
V1 violates).

**Reasoning.** Writing the (MATMUL) contract in `SPEC.md` §4 forced the question
"for which coefficients is the guard defined?". The scalar `_print_Mul` uses the
same `c < 0` idiom safely because `as_coeff_Mul()` always returns a real Rational;
but `_print_MatMul` uses `as_coeff_mmul()`, whose coefficient `Mul(*scalars)` can
be **non-real** (e.g. the imaginary unit `I` for `MatMul(I, A)`). `I.is_number`
is `True`, so V1's second conjunct `I < 0` is evaluated and **raises
`TypeError`** — `str(I*A)` crashed, a regression from the pre-fix behaviour
`I*A`. PROOF §4 shows this as a *stuck* symbolic execution: under V1 there is no
rewrite for the `nonreal` coefficient case, so the (MATMUL) totality claim has no
derivation.

`c.is_negative` is `False` for non-real numbers (so the `else`/empty-sign branch
fires — no crash) and, on every **real** number, is definitionally equal to
`c < 0`. Therefore PROOF §4 proves the edit is **output-identical to V1 on the
entire in-scope domain** (so PO-MM-SIGN and every PO-REG-* still hold) while
additionally discharging PO-MM-TOTAL. The change is strictly safe: it can only
turn a crash into the correct string, never alter a previously-correct string.

---

## Non-change 1 (kept): `str._print_MatAdd` and `latex._print_MatAdd`

**Traces to:** PO-ADD-SEP, PO-ADD-NOPLUSNEG, PO-ADD-FAITHFUL, PO-ADD-LEAD — all
✅ in PROOF §2 (the (LOOP) circularity + (MATADD) contract). FINDINGS **F2, F4,
F6**.

The loop provably renders every negative term with a `-` separator and never
emits the buggy `"+ -"` (PROOF §2 corollary), which is the prompt's core
obligation. I considered three deviations and rejected each:

- **F2 (empty MatAdd → `l.pop(0)` IndexError):** kept. An empty MatAdd is
  unreachable — `MatAdd.validate` indexes `args[0]` and raises before such an
  object exists, and the mirrored scalar `_print_Add` has the identical
  `l.pop(0)` for the same reason. PO-ADD-TOTAL is therefore stated on the domain
  `n ≥ 1`; adding a guard would diverge from the `_print_Add` idiom for an input
  that cannot occur.
- **F4 (latex double space for composite negative coefficients):** kept. It is
  LaTeX-invisible (whitespace collapses), untested, and the only inputs affected
  are composite-coefficient terms (`-sqrt(2)`, `-2*x`) in a non-leading MatAdd
  slot. A fix (`lstrip`) would create a *different* inconsistency in the leading
  slot and diverge from the strip-rejoin idiom the visible tests target.
- **F6 (dead `precedence < PREC` parens branch):** kept for verbatim parity with
  `_print_Add`; PROOF §2's case split collapses to the reachable `else` branch.

## Non-change 2 (kept): `latex._print_MatMul`

**Traces to:** PO-MM4-NEG1, PO-MM4-TOTAL, PO-REG-MM — all ✅ in PROOF §5.

`args[0] == -1` is a **total** equality test (sympy `__eq__` returns `False` on
incomparable operands, never raises — contrast the `c < 0` problem in str), so
there is no totality defect here. PROOF §5 shows every non-`-1` coefficient is
byte-for-byte unchanged (preserving the eight `test_matMul` rows) and `-1` folds
to a single leading `-`. No edit warranted.

## Non-change 3 (kept): `pretty._print_MatAdd`

**Traces to:** PO-PRETTY-SEP, PO-PRETTY-TOTAL, PO-REG-EL — all ✅ in PROOF §6.
FINDING **F3**.

The negativity test `S(item.args[0]).is_negative` is heuristic (F3), but PROOF §6
checks it is correct for **every term type that occurs** (MatMul coefficient,
MatrixSymbol name, explicit-matrix row count). Decisively, the model reproduces
`(-B + A)[0, 0]` — the expectation of the **pre-existing, already-passing**
`test_pretty::test_MatrixElement_printing` — which is independent evidence the
pretty model is faithful (positive finding P3). The two alternatives are worse:
slicing a 2-D `prettyForm` is awkward, and `item.as_coeff_mmul()` raises
`AttributeError` on an explicit `MatrixBase` term that the current code survives.
Kept.

---

## Why the audit did not regenerate more of the fix

Per the FVK loop, code is only edited when an obligation is violated. **PO-MM-TOTAL
is the sole violated obligation**; every other obligation in
[`PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md) holds in both V1 and V2,
and PROOF §2–§6 construct the discharges. F2/F3/F4/F5/F6 are corner/cosmetic/
scope items explicitly retained with reasons above and in
[`ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md) §3. No `[ESCALATION
BOUNDARY]` arose — the fragment is finite-string arithmetic inside the bundled
tier.

## Honesty gate

The proof is **constructed, not machine-checked** (the MVP does not run
`kompile`/`kprove`; commands are emitted in PROOF §8). The F1 finding and its fix
do **not** depend on the machine check — `str(I*A)` raising `TypeError` under V1
is a concrete, reproducible defect today. Test-removal suggestions in PROOF §9 are
recommendation-only and conditioned on a future `kprove ⇒ #Top`; I did not modify
or delete any test.

## Net effect

V1 already satisfied the issue's printing contract for all real-coefficient
matrix expressions (the entire scope of the bug report). V2 = V1 + one safe guard
change that removes a latent crash on non-real coefficients, with proof that no
in-scope output changes.
