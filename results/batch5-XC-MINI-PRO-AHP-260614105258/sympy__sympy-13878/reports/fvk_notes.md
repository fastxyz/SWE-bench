# reports/fvk_notes.md — FVK audit decisions for sympy__sympy-13878

This traces every V2 decision to entries in `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`. The audit applied the FVK method (`/formalize` → `/verify`) to the
V1 precomputed-CDF fix: I wrote a CDF specification (`fvk/SPEC.md`), enumerated proof
obligations, and constructed the proof (`fvk/PROOF.md`). One real bug surfaced and was fixed;
everything else is confirmed correct with justification.

## The one code change

**`repo/sympy/stats/crv_types.py` — `FrechetDistribution._cdf`: guard `x >= m` → `x > m`.**

- **Why:** Finding **F1** (BUG), obligation **PO-B-FRECHET**. Writing spec obligation **L8**
  ("a CDF equals 0 below its support") and evaluating each `_cdf` at its support boundary —
  the canonical "clean spec flushes the corner case" mechanism — showed that under `x >= m`,
  `cdf(Frechet(...))(m)` computes `exp(-(0**(-a))) = exp(-zoo) = nan`, but the correct value is
  `F(m) = P(X ≤ m) = 0`. The fix routes `x = m` to the `(S.Zero, True)` branch.
- **Why it is safe (no test regression):** PROOF.md §5 shows that for every `x > m` — the open
  support and *all* test points, including the issue's own `…(3) → exp(-1)` — the active branch
  and its value are identical to V1; only the single measure-zero boundary value changes from
  `nan` to `0`. PO-D-FRECHET (the `F'=pdf` obligation) is unaffected. The diff/numeric test the
  issue prescribes samples interior points, so the change is invisible to it while strictly
  improving correctness.
- **Contrast that justified fixing *only* Frechet:** Finding **F2** shows Dagum's analogous
  `x >= 0` is *not* a bug — its outer operation is a negative power, and `(1+zoo)**(-p) =
  zoo**(-p) = 0` lands on the correct value. So I fixed the branch that returns `nan` and left
  the branch that returns the correct `0`, minimizing churn (PO-B-DAGUM).

## Decisions to keep V1 unchanged (each justified)

- **All eleven closed forms stand.** Finding **F4** / obligations **PO-D-ARCSIN … PO-D-NAKAGAMI**:
  every CDF differentiates symbolically back to the coded pdf on the open support; the eight
  elementary/`lowergamma`/`uppergamma` cases are discharged in closed form in PROOF.md §2, with
  full derivations. No formula error was found, so no formula was touched.

- **StudentT `hyper` form kept.** Findings **F8** / **PO-D-STUDENTT** (`[numeric]`). The
  derivative identity is correct (anchored analytically by the `nu=1` Cauchy reduction
  `1/2 + atan(x)/pi`) but is not closed-form-simplifiable by SymPy — a *proof-capability* gap,
  not a code defect. The `hyper` form is exactly what intent **L5** requested. Kept; routed to
  numeric verification (ITERATION_GUIDANCE **G2**).

- **UniformSum `Sum` form kept.** Findings **F7** / **PO-D-UNIFORMSUM** (`[loop]`). The
  per-term summation circularity (SPEC §5) proves `F'=f` for non-integer `x`; SymPy's
  `Sum._eval_derivative` stalls on `floor(x)` in the limit, so the check is numeric, not
  symbolic. This is the canonical Irwin–Hall CDF (intent **L5**) and is correct; verifying it
  symbolically is the method limitation, handled by numeric tests (**G1**).

- **`meijerg=True` path untouched.** Finding **F6** / **PO-FRAME** (frame intent **L7**):
  `_cdf` is consulted only when `len(kwargs)==0`, so the Gamma/Erlang `meijerg` doctests keep
  integrating. Confirmed by inspection of `crv.py:214-220`; no change needed.

- **Erlang/Gamma exactness confirmed, not changed.** Finding **F5** / **PO-D-GAMMA**: with the
  shared `GammaDistribution._cdf`, `cdf(Erlang("x",1,1))(1) = 1 - exp(-1)` (exact), resolving
  intent **L4** (the V0 float `0.632…`). Already correct in V1.

- **`S(x)` wrappers left as-is.** Finding **F11** (cosmetic no-op, `x` is always symbolic);
  changing them is pure churn with no behavioral effect.

## Decisions to defer (out of scope, recorded)

- **No parameter-validation `check` methods added; `set` mismatches left.** Findings **F9/F10**
  / **PO-VALID** (`[out of scope]`). These are pre-existing and shared with the pdf; the issue
  is about *evaluating* the CDF, and `_cdf` already uses the true support guard independent of
  `set`. Bundling validity changes would expand scope and risk unrelated test churn. Routed to a
  separate pass (**G3**).

- **Dagum not hardened to `x > 0`.** Finding **F2** / **G4**: the value is already correct;
  hardening is optional uniformity, deliberately skipped to keep the diff minimal.

## Audit outcome

The V1 formulas were all mathematically correct (PO-D-* and PO-B-* discharge). The FVK boundary
obligation L8 surfaced exactly one real defect — Frechet returning `nan` at `x = m` — which V2
fixes with a one-token guard change. The two special-function CDFs (StudentT, UniformSum) carry
honest, explicitly-scoped *verification-method* caveats (numeric, not symbolic), not code bugs.
All artifacts: `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`,
`fvk/ITERATION_GUIDANCE.md`.
