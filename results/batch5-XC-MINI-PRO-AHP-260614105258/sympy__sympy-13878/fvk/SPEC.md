# SPEC.md — formal specification of the precomputed CDFs

**Target:** the `_cdf` methods added to `repo/sympy/stats/crv_types.py` for the twelve
distributions named in the issue (Arcsin, Dagum, Erlang, Frechet, Gamma, GammaInverse,
Kumaraswamy, Laplace, Logistic, Nakagami, StudentT, UniformSum — with Erlang and Gamma
sharing one `GammaDistribution._cdf`, so **11 methods**).

> **Mode.** This is *intent-spec mode* (per `formalize.md` §2): the specification is the
> *mathematical* CDF demanded by the issue, and the code is checked against it. It is not a
> reverse-engineering of "whatever the code does."

> **Adaptation note.** The FVK fast-path is written for imperative integer/map programs in a
> mini-X K semantics. This target is a *symbolic-algebra* library: the "program" is SymPy
> expression construction + symbolic differentiation, not a `while` loop over a store. I
> therefore (a) describe a faithful **mini-SymPy** evaluation fragment in §2, (b) state each
> `_cdf` as a **reachability claim** `cdf(X)(x) ⇒ F(x)` in §4, and (c) treat the
> Fundamental-Theorem-of-Calculus identity `d/dx F = pdf` as the postcondition discharged by
> symbolic differentiation (the role symbolic execution + VC discharge plays in the recipe).
> UniformSum contains a genuine bounded summation (`Sum_{k=0}^{floor(x)}`), which is the one
> place the **loop-circularity / induction** machinery of §5 applies literally.

---

## 1. Public intent ledger

Built from `benchmark/PROBLEM.md` (the issue), the docstring references, and the existing
`_cdf` precedents in the code. Source tags: `prompt` = the issue text; `docs` = the
Wikipedia reference already cited in each docstring; `code` = implementation fact;
`test` = the public example in the issue.

| # | Source | Evidence (quote / fact) | Semantic obligation | Status |
|---|--------|-------------------------|---------------------|--------|
| L1 | prompt | "the CDF is meant to be obtained by integration. This often doesn't work well … we should have an internal `_cdf` method with a precomputed CDF, as is the case for Normal and Uniform" | Each listed distribution must override `_cdf` to return a closed form; the integration path must no longer be taken when no kwargs are given. | met by V1 |
| L2 | prompt | "A way to test … is to differentiate it and compare with the PDF … Numeric comparison at a few random floats should be enough" | For each distribution, `d/dx F(x) = pdf(x)` for `x` in the open support. **This is the central postcondition.** | met (proof §PO-D*) |
| L3 | prompt | "Returns `Integral(... )/pi` which is incorrect, and doesn't converge" (Arcsin); "hangs" (Dagum, Frechet, GammaInverse, Kumaraswamy, Nakagami, StudentT, UniformSum) | `cdf(X)(v)` must *terminate* and return a value free of unevaluated `Integral` over the pdf. | met by V1 |
| L4 | prompt | "Returns `0.632120558828558`. I don't think this should be a float, given the inputs are not floats" (Erlang) | With exact (non-float) inputs the result must be exact (no premature float). | met by V1 |
| L5 | prompt | "expressed in terms of lowergamma / uppergamma / gamma / hypergeometric, which SymPy has"; "simple formula, with no special functions" | Use the canonical special functions (`lowergamma`, `uppergamma`, `hyper`) / elementary closed forms named in the issue. | met by V1 |
| L6 | docs | each docstring's Wikipedia link gives the reference CDF | `F` equals the standard reference CDF for the distribution. | met by V1 |
| L7 | code | `SingleContinuousDistribution.cdf(x, **kwargs)` consults `_cdf(x)` **only when `len(kwargs)==0`** | `cdf(X, meijerg=True)` must still route through integration (preserve existing doctests). | met by V1 (frame condition) |
| L8 | code | a CDF is a probability: it must be monotone non-decreasing with `F→0` at `-∞`, `F→1` at `+∞`, and `0≤F≤1`, and `=0`/`=1` outside a bounded support | `F` is a valid distribution function (boundary + range + monotonicity). | met on open support; boundary point caveats → FINDINGS F1–F3 |

If no external prompt existed this spec would be marked "inferred from code/docs/tests"; here
the issue prompt is explicit and is the primary spec source.

---

## 2. mini-SymPy — the evaluation fragment the code uses

The constructs actually exercised by `cdf(X)(v)`:

```
# dispatch (sympy/stats/crv.py)
cdf(self, x, **kwargs):
    if len(kwargs)==0 and self._cdf(x) is not None: return self._cdf(x)   # (DISPATCH)
    else: return compute_cdf(**kwargs)(x)                                  # integration path
SingleContinuousPSpace.compute_cdf(X): return Lambda(z, X.distribution.cdf(z))  # (LAMBDA)
Lambda(z, body)(v): body[z := v]                                            # (SUBST)
```

The expression algebra used inside the `_cdf` bodies:

```
Piecewise((e1,c1),(e2,c2),...) : returns first ei whose ci is (decidably) True   (PW)
   - on a concrete v, conditions are decided and the matching branch's value returned
   - on symbolic x with undecidable ci, stays a Piecewise (carried symbolically)
pow(b,e), exp, sqrt, asin, gamma, lowergamma, uppergamma, hyper, Sum, binomial, factorial, floor
```

Differentiation rules (the "semantic rules" the proof rewrites with), all present in SymPy:

```
(D-asin)   d/dz asin(z)                = 1/sqrt(1 - z**2)
(D-exp)    d/dz exp(z)                 = exp(z)
(D-pow)    d/dz z**c                   = c*z**(c-1)
(D-lower)  d/dz lowergamma(a,z)        = z**(a-1)*exp(-z)          # gamma_functions.py:256
(D-upper)  d/dz uppergamma(a,z)        = -z**(a-1)*exp(-z)         # gamma_functions.py:403
(D-hyper)  d/dz hyper((a,b),(c,),z)    = (a*b/c)*hyper((a+1,b+1),(c+1,),z)   # hyper.py fdiff/_eval_derivative
(D-chain)  d/dz g(h(z))                = g'(h(z))*h'(z)
(D-pw)     d/dz Piecewise((ei,ci))     = Piecewise((ei',ci))       # branch-wise, no Dirac terms
(D-sum)    d/dz Sum(f(k,z),(k,0,U))    = Sum(d/dz f(k,z),(k,0,U))  # valid when U has no z; see §5 caveat
```

This fragment is faithful to the real SymPy and is all the proof needs.

---

## 3. Notation

`F_X(x)` is the value `cdf(X)(x)` returns; `f_X(x) = density(X)(x)` is the coded pdf;
`(L,U)` is the open support. Uppercase letters are distribution parameters (symbolic,
constrained by `requires`); `x` is the argument.

---

## 4. Function contracts (one reachability claim per `_cdf`)

Each claim reads: *from `cdf(X)(x)` with the precondition, evaluation reaches `F(x)`, and
`F` satisfies the CDF properties (FTC derivative on the interior + the boundary/range frame).*
`[verified]` = derivative identity discharged symbolically in PROOF.md; `[numeric]` =
identity holds but is discharged by numeric evaluation, not closed-form simplification.

### (ARCSIN)  `ArcsinDistribution(a,b)`, support `(a,b)` — `[verified]`
```
requires a < b
cdf ⇒ F(x) = Piecewise((0, x<a), (2*asin(sqrt((x-a)/(b-a)))/pi, x<=b), (1, True))
post:  F'(x) = 1/(pi*sqrt((x-a)*(b-x)))  on a<x<b ;  F(a)=0 ; F(b)=1
```
SPEC-PROVENANCE: prompt "CDF is basically the arcsin function" (L3); docs Arcsine_distribution (L6).

### (DAGUM)  `DagumDistribution(p,a,b)`, support `(0,∞)` — `[verified]`
```
requires p>0, a>0, b>0
cdf ⇒ F(x) = Piecewise(((1+(x/b)**(-a))**(-p), x>=0), (0, True))
post:  F'(x) = a*p/x*(x/b)**(a*p)/((x/b)**a+1)**(p+1)  on x>0 ;  F(0+)=0 ;  F(∞)=1
```
SPEC-PROVENANCE: prompt "simple formula, with no special functions" (L5); docs Dagum_distribution.

### (GAMMA/ERLANG)  `GammaDistribution(k,theta)`, support `(0,∞)` — `[verified]`
```
requires k>0, theta>0           # Erlang = GammaDistribution(k, 1/l), so this covers both
cdf ⇒ F(x) = Piecewise((lowergamma(k, x/theta)/gamma(k), x>0), (0, True))
post:  F'(x) = x**(k-1)*exp(-x/theta)/(gamma(k)*theta**k)  on x>0 ;  F(0+)=0 ;  F(∞)=1
```
SPEC-PROVENANCE: prompt "directly expressed in terms of lowergamma" + "should not be a float" (L4,L5).

### (FRECHET)  `FrechetDistribution(a,s,m)`, support `(m,∞)` — `[verified]`
```
requires a>0, s>0
cdf ⇒ F(x) = Piecewise((exp(-((x-m)/s)**(-a)), x>m), (0, True))    # V2: x>m  (was x>=m)
post:  F'(x) = a/s*((x-m)/s)**(-1-a)*exp(-((x-m)/s)**(-a))  on x>m ;  F(m)=0 ;  F(∞)=1
```
SPEC-PROVENANCE: prompt "hangs … simple formula" (L3,L5); docs Frechet_distribution.
**Boundary obligation L8 fails at x=m under `>=m` (nan) → fixed in V2; see FINDINGS F1.**

### (GAMMAINVERSE)  `GammaInverseDistribution(a,b)`, support `(0,∞)` — `[verified]`
```
requires a>0, b>0
cdf ⇒ F(x) = Piecewise((uppergamma(a, b/x)/gamma(a), x>0), (0, True))
post:  F'(x) = b**a/gamma(a)*x**(-a-1)*exp(-b/x)  on x>0 ;  F(0+)=0 ;  F(∞)=1
```
SPEC-PROVENANCE: prompt "directly expressed in terms of uppergamma" (L5).

### (KUMARASWAMY)  `KumaraswamyDistribution(a,b)`, support `(0,1)` — `[verified]`
```
requires a>0, b>0
cdf ⇒ F(x) = Piecewise((0, x<0), (1-(1-x**a)**b, x<=1), (1, True))
post:  F'(x) = a*b*x**(a-1)*(1-x**a)**(b-1)  on 0<x<1 ;  F(0)=0 ;  F(1)=1
```
SPEC-PROVENANCE: prompt "simple formula, with no special functions" (L5).

### (LAPLACE)  `LaplaceDistribution(mu,b)`, support `(-∞,∞)` — `[verified]`
```
requires b>0
cdf ⇒ F(x) = Piecewise((exp((x-mu)/b)/2, x<mu), (1-exp(-(x-mu)/b)/2, x>=mu))
post:  F'(x) = exp(-Abs(x-mu)/b)/(2b)  for x≠mu ;  F continuous at mu with F(mu)=1/2 ;  F(±∞)=0/1
```
SPEC-PROVENANCE: prompt "simple piecewise formula, with no special functions" (L5).

### (LOGISTIC)  `LogisticDistribution(mu,s)`, support `(-∞,∞)` — `[verified]`
```
requires s>0
cdf ⇒ F(x) = 1/(1+exp(-(x-mu)/s))
post:  F'(x) = exp(-(x-mu)/s)/(s*(1+exp(-(x-mu)/s))**2)  everywhere ;  F(±∞)=0/1
```
SPEC-PROVENANCE: prompt "throws an exception … simple formula" (L3,L5).

### (NAKAGAMI)  `NakagamiDistribution(mu,omega)`, support `(0,∞)` — `[verified]`
```
requires mu>0, omega>0
cdf ⇒ F(x) = Piecewise((lowergamma(mu, mu/omega*x**2)/gamma(mu), x>0), (0, True))
post:  F'(x) = 2*mu**mu/(gamma(mu)*omega**mu)*x**(2*mu-1)*exp(-mu/omega*x**2)  on x>0 ;  F(0+)=0 ;  F(∞)=1
```
SPEC-PROVENANCE: prompt "directly expressed in terms of gamma functions" (L5).

### (STUDENTT)  `StudentTDistribution(nu)`, support `(-∞,∞)` — `[numeric]`
```
requires nu>0
cdf ⇒ F(x) = 1/2 + x*gamma((nu+1)/2)*hyper((1/2,(nu+1)/2),(3/2,),-x**2/nu)/(sqrt(pi*nu)*gamma(nu/2))
post:  F'(x) = 1/(sqrt(nu)*beta(1/2,nu/2))*(1+x**2/nu)**(-(nu+1)/2)  everywhere ;  F(0)=1/2 ;  F(±∞)=0/1
```
SPEC-PROVENANCE: prompt "directly expressed in terms of hypergeometric function … important for tail estimates" (L5).

### (UNIFORMSUM)  `UniformSumDistribution(n)`, support `(0,n)`, `n∈ℤ⁺` — `[verified, loop]`
```
requires n integer, n>=1
cdf ⇒ F(x) = Piecewise((0, x<0),
                       (Sum((-1)**k*binomial(n,k)*(x-k)**n,(k,0,floor(x)))/factorial(n), x<=n),
                       (1, True))
post:  F'(x) = Sum((-1)**k*binomial(n,k)*(x-k)**(n-1),(k,0,floor(x)))/factorial(n-1)  on 0<x<n, x∉ℤ ;
       F(0)=0 ;  F(n)=1
```
SPEC-PROVENANCE: prompt "expressed by a sum similar to the PDF itself (which is already coded in)" (L5).
The derivative identity is the **per-term circularity** of §5.

---

## 5. The one genuine loop: UniformSum's summation circularity

`F(x)·n! = Σ_{k=0}^{⌊x⌋} (-1)^k C(n,k)(x-k)^n` and `f(x)·(n-1)! = Σ_{k=0}^{⌊x⌋} (-1)^k C(n,k)(x-k)^{n-1}`.

**Per-term invariant (the circularity):** for every `k`,
`d/dx [ (-1)^k C(n,k)(x-k)^n / n! ] = (-1)^k C(n,k)(x-k)^{n-1} / (n-1)!`,
because `d/dx (x-k)^n = n·(x-k)^{n-1}` and `n/n! = 1/(n-1)!`. Summing the invariant over the
(x-independent, since `x∉ℤ`) index range `k=0..⌊x⌋` gives `F'(x)=f(x)` term-by-term — this is
rule `(D-sum)`. The **side condition** is `x ∉ ℤ` (so `⌊x⌋` is locally constant and the upper
limit carries no `x`); on integer `x` the floor jump is a measure-zero set where the density is
irrelevant. This is the §5 loop-soundness side condition analog (cf. the `I ≤ N+1` guard).

---

## 6. The dispatch/frame contract (applies to all 11)

```
(DISPATCH)  cdf(X)(v)  with no kwargs  ⇒  Lambda(z, X._cdf(z))(v)  ⇒  X._cdf(z)[z:=v]
(FRAME-meijerg)  cdf(X, meijerg=True)(v)  ⇒  compute_cdf(meijerg=True)(v)   # _cdf NOT consulted (L7)
```
The frame condition (FRAME-meijerg) is what keeps the Gamma/Erlang `meijerg=True` doctests green.
