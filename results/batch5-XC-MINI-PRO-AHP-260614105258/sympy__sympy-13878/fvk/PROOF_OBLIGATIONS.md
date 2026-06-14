# PROOF_OBLIGATIONS.md

The obligations whose discharge constitutes a correctness proof of the precomputed CDFs.
Each is `[closed]` (dischargeable by closed-form symbolic rewriting with the §2 rules),
`[numeric]` (true, dischargeable only by numeric evaluation in the bundled tier),
`[loop]` (needs the §5 summation circularity), or `[inspect]` (by reading the dispatch code).
Discharges are written in PROOF.md.

Notation as in SPEC.md: `F` = value of `cdf(X)(x)`; `f` = `density(X)(x)`; `(L,U)` = open support.

---

## A. Dispatch / frame obligations (structural)

- **PO-DISP** `[inspect]` — For `cdf(X)(v)` with **no** kwargs, evaluation reaches
  `X._cdf(z)[z:=v]` (not the integration path). Justified by `crv.py:214-220`:
  `if len(kwargs)==0: cdf=self._cdf(x); if cdf is not None: return cdf`, and `_cdf` is
  overridden (non-`None`) for all 11 classes. Resolves intent L1, L3.

- **PO-FRAME** `[inspect]` — For `cdf(X, meijerg=True)(v)`, `_cdf` is **not** consulted, so the
  pre-existing integration doctests (Gamma, Erlang) are unchanged. Justified by the same guard
  (`len(kwargs)==0` is false). Resolves frame L7. (Finding F6.)

## B. Central derivative obligations  `F'(x) = f(x)` on `(L,U)` — resolve intent L2/L6

For each, the obligation is the first-order identity `d/dx F(x) − f(x) = 0` for `x ∈ (L,U)`.

| ID | Distribution | tier | discharged by |
|----|--------------|------|---------------|
| PO-D-ARCSIN | Arcsin | `[closed]` | (D-asin)+(D-chain): `d/dx (2/π)·asin(√((x−a)/(b−a)))` → `1/(π√((x−a)(b−x)))` |
| PO-D-DAGUM | Dagum | `[closed]` | (D-pow)+(D-chain): exponent algebra collapses to `a·p/x·(x/b)^{ap}/((x/b)^a+1)^{p+1}` |
| PO-D-GAMMA | Gamma & Erlang | `[closed]` | (D-lower): `d/dx lowergamma(k,x/θ)/Γ(k)` → `(x/θ)^{k-1}e^{-x/θ}/θ /Γ(k)` = `x^{k-1}e^{-x/θ}/(Γ(k)θ^k)` |
| PO-D-FRECHET | Frechet | `[closed]` | (D-exp)+(D-pow): `d/dx exp(-((x−m)/s)^{-a})` → `a/s·((x−m)/s)^{-1-a}·exp(-(…)^{-a})` |
| PO-D-GAMMAINV | GammaInverse | `[closed]` | (D-upper)+(D-chain): `d/dx uppergamma(a,b/x)/Γ(a)` → `b^a x^{-a-1}e^{-b/x}/Γ(a)` |
| PO-D-KUMAR | Kumaraswamy | `[closed]` | (D-pow)·2: `d/dx [1−(1−x^a)^b]` → `a·b·x^{a-1}(1−x^a)^{b-1}` |
| PO-D-LAPLACE | Laplace | `[closed]` | (D-exp) per branch: both branches give `e^{-|x−μ|/b}/(2b)` |
| PO-D-LOGISTIC | Logistic | `[closed]` | (D-pow)+(D-exp): `d/dx (1+e^{-(x−μ)/s})^{-1}` → `e^{-(x−μ)/s}/(s(1+e^{-(x−μ)/s})^2)` |
| PO-D-NAKAGAMI | Nakagami | `[closed]` | (D-lower)+(D-chain): `d/dx lowergamma(μ, μx²/ω)/Γ(μ)` → `2μ^μ x^{2μ-1}e^{-μx²/ω}/(Γ(μ)ω^μ)` |
| PO-D-STUDENTT | StudentT | `[numeric]` | (D-hyper)+(D-pow); closed-form `=0` needs a `₂F₁` contiguity identity SymPy won't auto-apply ⇒ numeric at concrete `nu`; analytic check via `nu=1` Cauchy reduction |
| PO-D-UNIFORMSUM | UniformSum | `[loop]` | §5 per-term circularity under side condition `x∉ℤ` (D-sum) |

## C. Boundary / limit obligations — resolve intent L8

For half-line / bounded supports, `F=0` at/below `L` and `F→1` at `U` (or `x→∞`).

- **PO-B-ARCSIN** `[closed]` — `F(a)=2·asin(0)/π=0`; `F(b)=2·asin(1)/π=2·(π/2)/π=1`; `x<a⇒0`, `x>b⇒1`. ✓
- **PO-B-DAGUM** `[closed]` — `F(0)=0` (Finding F2, via `zoo**(-p)=0`); `lim_{x→∞}(1+(x/b)^{-a})^{-p}=1^{-p}=1`. ✓ (value correct)
- **PO-B-GAMMA** `[closed]` — `x>0` guard; `lowergamma(k,0⁺)=0⇒F=0`; `lowergamma(k,∞)=Γ(k)⇒F=1`. ✓
- **PO-B-FRECHET** `[closed]` — **after F1 fix (`x>m`)**: `F(m)=0` via else-branch (was `nan`); `lim_{x→∞}exp(-((x−m)/s)^{-a})=exp(0)=1`. ✓
- **PO-B-GAMMAINV** `[closed]` — `x>0` guard ⇒ `F(0)=0` (the singular `b/x` is on the dead branch); `b/x→0⁺⇒uppergamma(a,0)=Γ(a)⇒F=1`. ✓
- **PO-B-KUMAR** `[closed]` — `F(0)=1−(1−0)^b=0`; `F(1)=1−0^b=1`; `x<0⇒0`, `x>1⇒1`. ✓
- **PO-B-LAPLACE** `[closed]` — `lim_{x→−∞}e^{(x−μ)/b}/2=0`; `lim_{x→∞}1−e^{-(x−μ)/b}/2=1`; continuity at `μ`: both branches `=1/2`. ✓
- **PO-B-LOGISTIC** `[closed]` — `lim_{x→−∞}=1/(1+∞)=0`; `lim_{x→∞}=1/(1+0)=1`. ✓
- **PO-B-NAKAGAMI** `[closed]` — `x>0` guard ⇒ `F(0)=0`; `lowergamma(μ,∞)=Γ(μ)⇒F=1`. ✓
- **PO-B-STUDENTT** `[numeric]` — `F(0)=1/2`; `lim_{x→±∞}F=1/0` follows from the asymptotics of `x·₂F₁(…;−x²/ν)`; checked numerically. ✓
- **PO-B-UNIFORMSUM** `[closed]` — `F(0)=0^n/n!=0`; `F(n)=Σ_{k=0}^{n}(−1)^kC(n,k)(n−k)^n/n! = n!/n! = 1` (the standard finite-difference identity `Σ(−1)^kC(n,k)(n−k)^n=n!`); `x<0⇒0`, `x>n⇒1`. ✓

## D. Global shape obligations (consequences, not independently proved)

- **PO-RANGE** — `0 ≤ F(x) ≤ 1` for all `x`. Follows from `F'(x)=f(x) ≥ 0` (PO-D-*, densities
  are non-negative) + the boundary values `0`/`1` (PO-B-*) by monotonicity. `[closed]` given B+C.
- **PO-MONO** — `F` non-decreasing. Same justification (`F' = f ≥ 0`).
- **PO-CONT** — `F` continuous on `ℝ` (incl. at internal Piecewise seams). Checked at each seam
  in PO-B-* (e.g. Laplace at `μ`, Kumaraswamy at `0,1`, UniformSum at integer knots inside
  `(0,n)` where the two adjacent `Sum` forms agree). `[closed]`.

## E. Out-of-scope obligations (stated, not discharged here)

- **PO-VALID** `[ESCALATION BOUNDARY / out of scope]` — parameter validity (`a<b` for Arcsin,
  positivity for shape params). Pre-existing precondition shared with the pdf; stated as
  `requires` in SPEC §4, recorded as Finding F9. Not a goal of this issue. Routed to
  ITERATION_GUIDANCE G3 (add `check` methods).

---

### Coverage

Every spec claim in SPEC §4 has a derivative obligation (B) and, where the support is
bounded/half-line, boundary obligations (C); the dispatch (A) and global-shape (D) obligations
close the "is a valid CDF and is actually used" gap. The only `[numeric]`/`[loop]` items are
StudentT (hypergeometric) and UniformSum (summation) — both **true**, both flagged for numeric
testing, neither a code defect.
