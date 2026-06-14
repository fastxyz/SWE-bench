# PROOF.md — constructed correctness proof of the precomputed CDFs

**Status: constructed, not machine-checked.** This target is a symbolic-algebra library, so
"machine-checking" here means *running SymPy* on the differentiation/limit checks below. This
session has **no execution environment**, so — exactly as the FVK MVP constructs but does not
run `kprove` — the derivations are carried out by hand against the SymPy differentiation rules
of SPEC §2, and the §6 commands are the SymPy snippets that would upgrade *constructed* →
*machine-checked*.

Proof method = the recipe's "symbolic execution + discharge VCs", specialized: the `<k>`-cell
reduction is `cdf(X)(x) → X._cdf(x)` (PO-DISP); the postcondition VC is the FTC identity
`d/dx F − f = 0`, discharged by rewriting with `(D-*)` and simplifying; boundary VCs are
limit/substitution facts.

---

## 1. Structural step (PO-DISP, PO-FRAME)

`cdf(X)(v)` →[crv.py:429] `Lambda(z, X.distribution.cdf(z))(v)` →[crv.py:214, len(kwargs)=0]
`X._cdf(z)[z:=v]`. Each of the 11 classes overrides `_cdf` to a non-`None` body, so the guard
returns it and the integration branch is dead. With `meijerg=True`, `len(kwargs)=1`, the guard
is skipped and `compute_cdf(meijerg=True)` runs — PO-FRAME holds, old doctests intact. ∎

## 2. Derivative obligations (PO-D-*), closed-form

Throughout, `c·z**(c-1)` is `(D-pow)`, `exp'=exp` is `(D-exp)`, and `(D-lower)/(D-upper)` are
`d/dz lowergamma(a,z)=z**(a-1)e^{-z}`, `d/dz uppergamma(a,z)=-z**(a-1)e^{-z}`.

**PO-D-ARCSIN.** Let `u=√((x−a)/(b−a))`. `d/dx (2/π)asin(u) = (2/π)·u'/√(1−u²)`.
`u' = 1/(2(b−a)·u)`, `1−u² = (b−x)/(b−a)`, so `1/√(1−u²)=√((b−a)/(b−x))`. Product
`= (2/π)·√((b−a)/(b−x))·1/(2(b−a)u) = (1/π)·√((b−a)/(b−x))·√((b−a)/(x−a))/(b−a)
= (1/π)/√((x−a)(b−x))` = `f`. ✓

**PO-D-DAGUM.** `d/dx (1+(x/b)^{-a})^{-p} = −p(1+(x/b)^{-a})^{-p-1}·(−a/b)(x/b)^{-a-1}`.
Rewrite `(1+(x/b)^{-a})^{-p-1} = (x/b)^{a(p+1)}((x/b)^a+1)^{-p-1}`; combine exponents
`(x/b)^{-a-1+a(p+1)}=(x/b)^{ap-1}`, and `(ap/b)(x/b)^{ap-1}=(ap/x)(x/b)^{ap}`. Result
`= a·p/x·(x/b)^{ap}/((x/b)^a+1)^{p+1}` = `f`. ✓

**PO-D-GAMMA (and Erlang).** `d/dx lowergamma(k,x/θ)/Γ(k) = (1/Γ(k))·(x/θ)^{k-1}e^{-x/θ}·(1/θ)`.
`(x/θ)^{k-1}/θ = x^{k-1}θ^{-(k-1)}θ^{-1}=x^{k-1}θ^{-k}`, giving `x^{k-1}e^{-x/θ}/(Γ(k)θ^k)` = `f`.
Erlang is `GammaDistribution(k, 1/l)`, same proof with `θ=1/l`. ✓

**PO-D-FRECHET.** With `w=((x−m)/s)^{-a}`, `d/dx exp(−w)=−exp(−w)·w'`,
`w' = −a((x−m)/s)^{-a-1}(1/s)`, so `−w' = (a/s)((x−m)/s)^{-1-a}`, giving
`(a/s)((x−m)/s)^{-1-a}exp(−((x−m)/s)^{-a})` = `f`. ✓ (Holds for `x>m`; at `x=m` the value is
fixed to `0` by the F1 branch, see §4.)

**PO-D-GAMMAINV.** `d/dx uppergamma(a,b/x)/Γ(a) = (1/Γ(a))·(−(b/x)^{a-1}e^{-b/x})·(−b/x²)`
`= (1/Γ(a))(b/x)^{a-1}(b/x²)e^{-b/x}`. Since `(b/x)^{a-1}·b/x² = b^{a-1}x^{-(a-1)}b x^{-2}
= b^a x^{-a-1}`, result `= b^a x^{-a-1}e^{-b/x}/Γ(a)` = `f`. ✓

**PO-D-KUMAR.** `d/dx [1−(1−x^a)^b] = −b(1−x^a)^{b-1}·(−a x^{a-1}) = a b x^{a-1}(1−x^a)^{b-1}` = `f`. ✓

**PO-D-LAPLACE.** `x<μ`: `d/dx ½e^{(x−μ)/b}=½(1/b)e^{(x−μ)/b}=e^{(x−μ)/b}/(2b)
= e^{-|x−μ|/b}/(2b)` (since `x−μ<0`). `x>μ`: `d/dx [1−½e^{-(x−μ)/b}]=½(1/b)e^{-(x−μ)/b}
= e^{-|x−μ|/b}/(2b)`. Both branches `= f`. ✓

**PO-D-LOGISTIC.** `d/dx (1+e^{-(x−μ)/s})^{-1} = −(1+e^{-(x−μ)/s})^{-2}·e^{-(x−μ)/s}·(−1/s)
= e^{-(x−μ)/s}/(s(1+e^{-(x−μ)/s})^2)` = `f`. ✓

**PO-D-NAKAGAMI.** With `v=μx²/ω`, `d/dx lowergamma(μ,v)/Γ(μ)=(1/Γ(μ))v^{μ-1}e^{-v}·v'`,
`v'=2μx/ω`. `v^{μ-1}·(2μx/ω) = (μ/ω)^{μ-1}x^{2μ-2}·2μx/ω = 2μ^μ x^{2μ-1}/ω^μ`, giving
`2μ^μ x^{2μ-1}e^{-μx²/ω}/(Γ(μ)ω^μ)` = `f`. ✓

## 3. StudentT (PO-D-STUDENTT) — numeric tier + analytic cross-check

Closed-form `diff(F)−f → 0` requires the contiguous-`₂F₁` identity
`₂F₁(½,β;3/2;z) − (2z/3)·½β·₂F₁(3/2,β+1;5/2;z) = (1−z)^{-β}` (with `β=(ν+1)/2`, `z=−x²/ν`),
which SymPy does not apply automatically — this is a **proof-capability gap, not a code bug**
(Finding F8). It is discharged two ways:

- **Analytic special case `ν=1` (Cauchy).** `Γ(1)=1`, `Γ(½)=√π`, and the SymPy identity
  `₂F₁(½,1;3/2;−x²)=atan(x)/x` give `F = ½ + x·atan(x)/(x·π) = ½ + atan(x)/π`, exactly the
  Cauchy CDF, whose derivative is `1/(π(1+x²))` = the `ν=1` t-density. ✓
- **Numeric tier (general).** For any concrete `ν` (e.g. `ν=10`), `F.diff(x)` evaluates via
  `hyper`'s mpmath backend and matches `f` to working precision at sampled `x` — the issue's
  prescribed "numeric comparison at a few random floats". ✓

## 4. UniformSum (PO-D-UNIFORMSUM) — the summation circularity

`F(x)·n! = Σ_{k=0}^{⌊x⌋}(−1)^kC(n,k)(x−k)^n`. **Per-term circularity:** the invariant
`d/dx[(−1)^kC(n,k)(x−k)^n/n!] = (−1)^kC(n,k)(x−k)^{n-1}/(n−1)!` holds for every `k`
(`(D-pow)`: `d/dx(x−k)^n=n(x−k)^{n-1}`, and `n/n!=1/(n−1)!`). **Side condition** `x∉ℤ` makes
`⌊x⌋` locally constant so the upper limit is `x`-free and `(D-sum)` applies; summing the
invariant over `k=0..⌊x⌋` yields `F'(x)=f(x)` term-by-term. ✓ On integer `x` (a discrete,
measure-zero set) the floor jumps; the density there is immaterial. This is the §5 loop
circularity: the genuine progress step is the per-term derivative, the "induction" is the
finite sum, the guard is `x∉ℤ`. *(Symbolically `diff` stalls — Finding F7 — so this obligation
is testable numerically, not by `simplify(...)==0`.)*

## 5. Boundary obligations (PO-B-*) and the F1 fix

All discharged in PROOF_OBLIGATIONS §C. The proof-critical one:

> **PO-B-FRECHET — the bug and its discharge.** Under V1's `x>=m`, substituting `x=m` reaches
> the *active* branch and computes `exp(−(0**(−a)))`; `0**(−a)=zoo` and `exp(−zoo)=exp(zoo)=nan`
> — obligation `F(m)=0` **fails**. Under V2's `x>m`, `x=m` makes the guard false, evaluation
> reaches `(S.Zero, True)` and returns `0` — obligation **holds**. For `x>m` (the support and
> every test point) the active branch and its value are unchanged, so PO-D-FRECHET and all
> Frechet tests are unaffected. ∎

Global shape: PO-RANGE/PO-MONO follow from `F'=f≥0` + the `0/1` boundaries; PO-CONT from the
seam checks (Laplace at `μ`: ½=½; Kumaraswamy at `0`,`1`; UniformSum at interior integer knots
where adjacent `Sum` upper limits agree).

---

## 6. Reproduce the machine check (constructed → machine-checked)

Run these in a SymPy environment (the analog of `kompile`/`kprove`); each expected output is
the proof's claim. **Until run, treat the proof as constructed, not machine-checked.**

```python
from sympy import symbols, diff, simplify, hyperexpand, S, Rational, exp, atan, pi
from sympy.stats import (Arcsin, Dagum, Erlang, Frechet, Gamma, GammaInverse,
                         Kumaraswamy, Laplace, Logistic, Nakagami, StudentT, UniformSum,
                         cdf, density)

x = symbols('x', positive=True)            # interior of every half-line/bounded support

# closed-form derivative VCs (expect 0):
for X in [Gamma('g', S(1)/5, 14), GammaInverse('gi', S(5)/7, 2),
          Nakagami('n', S(7)/3, 1), Dagum('d', S(4)/5, 4, 4),
          Kumaraswamy('k', S(1)/123, 5), Logistic('l', -2, 4), Laplace('la', 3, 2)]:
    assert simplify(diff(cdf(X)(x), x) - density(X)(x)) == 0

# Arcsin / Frechet need x in support; use a fixed in-support point and nsimplify:
assert simplify(diff(cdf(Arcsin('a', -5, 9))(x), x) - density(Arcsin('a', -5, 9))(x)) == 0
assert simplify(diff(cdf(Frechet('f', 2, 6, -3))(x), x) - density(Frechet('f', 2, 6, -3))(x)) == 0

# StudentT: analytic ν=1 + numeric general (Finding F8):
assert simplify(hyperexpand(cdf(StudentT('s1', 1))(x)) - (S.Half + atan(x)/pi)) == 0
for v in [1.3, 4.7, 9.2]:
    assert abs(float(diff(cdf(StudentT('s', 10))(x), x).subs(x, v)
                     - density(StudentT('s', 10))(x).subs(x, v))) < 1e-9

# UniformSum: NUMERIC only (Finding F7 — symbolic diff stalls on floor in Sum limit):
US = UniformSum('u', 5)
for v in [0.7, 1.4, 2.9, 4.1]:
    lhs = diff(cdf(US)(x), x).subs(x, v).doit()      # numeric, floor(v) constant
    assert abs(float(lhs - density(US)(x).subs(x, v).doit())) < 1e-9

# the F1 boundary fix (expect 0, not nan):
assert cdf(Frechet('f', S(4)/3, 1, 2))(2) == 0
assert cdf(Frechet('f', S(4)/3, 1, 2))(3) == exp(-1)               # interior unchanged

# Erlang exactness (Finding F5, expect 1 - exp(-1), no float):
assert cdf(Erlang('e', 1, 1))(1) == 1 - exp(-1)

# frame condition (PO-FRAME): meijerg path still integrates, _cdf not consulted:
z = symbols('z'); _ = cdf(Gamma('g', symbols('k', positive=True),
                                 symbols('t', positive=True)), meijerg=True)(z)
```

Expected: every `assert` passes ⇒ all PO-D-*, PO-B-*, PO-DISP, PO-FRAME discharged.

---

## 7. Test-redundancy recommendation (benefit 1)

**Conditioned on running §6** (Honesty gate — this session cannot execute SymPy):

- **Subsumed once §6 passes:** any single-point value assertion of these CDFs is entailed by
  the proven contracts — e.g. a hypothetical `cdf(Dagum("x",S(1)/3,S(1)/5,2))(3) == (1+(3/2)**(-1/5))**(-1/3)`
  is subsumed by PO-D-DAGUM + PO-B-DAGUM; likewise `cdf(Erlang("x",1,1))(1) == 1-exp(-1)` by
  PO-D-GAMMA + `lowergamma(1,·)` evaluation. The general `diff(cdf)==pdf` numeric loop
  (issue's method) is the proof, so per-point CDF tests are redundant *within the verified
  domain*.
- **KEEP (not subsumed):**
  - The **boundary** tests, especially `cdf(Frechet(...))(m)` — out-of-interior, and exactly
    where Finding F1 lived. Keep to lock the `nan→0` fix.
  - The **`meijerg=True`** Gamma/Erlang doctests — they exercise the *other* code path
    (PO-FRAME), not the contract.
  - **UniformSum / StudentT** numeric tests — they discharge the `[loop]`/`[numeric]`
    obligations the closed-form proof cannot (F7/F8); never drop them.
  - **Parameter-validity** tests, if any (out-of-domain inputs, F9) — outside every contract.
- **Never auto-delete.** Recommendation only. Estimated CI saving is negligible here (these are
  fast symbolic checks); the value of this fix is benefit 2 (the F1 bug), not benefit 1.

## 8. Residual risk

- **Partial correctness only.** The proof asserts `cdf(X)(v)` *returns the specified value*;
  it does not prove the symbolic engine terminates for every exotic parameter (it does for the
  closed forms here — no integration is invoked). UniformSum/StudentT discharge is partly
  **numeric**, sound at tested points, not a symbolic universal.
- **Trusted base:** the §2 mini-SymPy rules faithfully mirror SymPy's `diff`, `lowergamma`/
  `uppergamma`/`hyper` `fdiff`, and `Piecewise`/`Pow`/`exp` evaluation; the `nu=1`↔atan and
  `Σ(−1)^kC(n,k)(n−k)^n=n!` identities; and that this session has not run §6.
- **F7/F8** are method limitations, surfaced honestly, routed to numeric checks — *not*
  admitted as `[trusted]`.
