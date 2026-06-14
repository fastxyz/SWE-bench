# ITERATION_GUIDANCE.md — sympy-14248

Feedback package for the next generate→formalize→verify pass. Ordered by value.

---

## 1. Change applied this pass (V1 → V2)

**str `_print_MatMul`: `if c.is_number and c < 0:` → `if c.is_number and c.is_negative:`**
(plus an explanatory comment).

- **Driver:** FINDING **F1** / obligation **PO-MM-TOTAL**.
- **Why:** `as_coeff_mmul()` can yield a non-real numeric coefficient (`I`);
  `I < 0` raises `TypeError`, so V1 crashed on `str(I*A)` — a regression vs.
  pre-fix. `is_negative` is `False` for non-reals (no raise) and equals `c < 0`
  on every real number, so all in-scope outputs are unchanged.
- **Confidence:** high. The equivalence on reals is a definitional fact
  (PROOF §4); the fix only adds a defined result on the previously-stuck branch.

No other source edits. F2–F6 were **deliberately kept** (see §3).

---

## 2. UltimatePowers questions (intent the prompt left open)

1. **Non-real coefficients.** "Should `I*A` (imaginary-unit-scaled matrix) print
   as `I*A`, `1.0*I*A`, or is it out of the supported domain?" — V2 prints `I*A`
   (matches pre-fix). Confirm that is the desired contract.
2. **Symbolic negative coefficients (F5).** "For `A - x*B` with `x` a plain
   symbol, do you want `A - x*B` (fold the sign) or `A + (-x)*B` (current)?" — the
   issue only specified the *numeric* `-1` case; this is unspecified.
3. **Empty/degenerate MatAdd (F2).** "Is an empty `MatAdd` (only buildable via
   `check=False`) in the domain at all?" — current answer: no; `validate` blocks
   it. If it must be total, add a guard mirroring `' + '.join`.
4. **latex spacing (F4).** "Does the *string* (not just the rendered output) of
   `latex(2*x*A - sqrt(2)*B)` matter?" — if yes, the strip-rejoin needs an
   `lstrip`/`_coeff_isneg`-style rewrite; if rendering is what matters, leave it.

---

## 3. Recommended next code/spec changes (and explicit non-changes)

| Finding | Recommendation | Decision this pass |
|---|---|---|
| F1 | guard with `is_negative` | **DONE (V2)** |
| F2 (empty) | optional one-line guard `if not l: return ""` | **keep V1** — unreachable; diverges from `_print_Add` idiom |
| F3 (pretty heuristic) | optionally detect negativity via the rendered `prettyForm`'s leading glyph | **keep V1** — correct for all occurring terms; alternatives are worse (AttributeError on explicit matrices) |
| F4 (latex double space) | `lstrip` after the strip, or `_coeff_isneg`-on-args detection | **keep V1** — LaTeX-invisible; would diverge from the idiom the tests target |
| F5 (symbolic neg) | extend the sign fold to `is_negative` symbolic coeffs | **keep V1** — out of issue scope |
| F6 (dead parens branch) | could drop the `precedence < PREC` branch | **keep V1** — verbatim parity with `_print_Add` |

The audit's conclusion: **V1 was correct on the issue's domain; V2 fixes the one
genuine over-reach (a totality regression on non-real coefficients) and confirms
the rest.**

## 4. Tests to add / keep / (conditionally) drop

- **ADD:** `str(MatMul(I, A)) == 'I*A'` — regression pin for F1 (out-of-fragment
  totality; never subsumed by the proof, always keep).
- **KEEP:** `test_pretty::test_MatrixElement_printing` (validates the T5 model);
  `test_latex::test_matAdd` (also pins the PO-ORDER assumption); any
  termination/integration tests.
- **Conditionally redundant** (only after `kprove` ⇒ `#Top`): the in-domain
  string-equality points in `test_matMul` / `test_MatMul_MatAdd` /
  `test_MatrixElement_printing`. CI savings negligible; not worth removing.

## 5. If extending the spec next pass

- Promote the trusted lemma **L1** ("a matrix factor never prints with a leading
  `-`") to a checked claim by enumerating the printer methods for the factor
  sorts (MatrixSymbol/MatPow/Transpose/Inverse/Identity/ZeroMatrix/MatrixBase).
- Model `_print_MatMul`'s `_keep_coeff` fold explicitly (currently abstracted as
  "BODY does not lead with `-`") to discharge PO-MM-SIGN without trusting L1.
- Wire a real per-language (mini-CPython) string semantics to retire the
  mini-X adequacy assumption (roadmap item).

## 6. Residual risk carried forward

Partial-correctness caveat is vacuous here (the loop is structural/terminating).
The live residual risks are the **mini-X adequacy** assumption and **L1**; both
are low (string ops are standard; L1 is a stable property of matrix printers).
Everything is within the bundled proof tier — no escalation boundary.
