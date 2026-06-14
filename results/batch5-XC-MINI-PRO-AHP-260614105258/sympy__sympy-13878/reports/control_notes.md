# Control notes — review outcome for sympy__sympy-13878

## Summary of decision

After a systematic, skeptical re-review (recorded in `review/FINDINGS.md`), **V1
stands unchanged**. No source edits were made in this pass. Every formula is
mathematically correct, the one genuine risk (a new `.doit()` code path) was shown to
terminate, and the only imperfections found are cosmetic or non-attainable boundary
points whose "fix" would carry more risk than the wart. Each decision below is traced
to numbered findings.

## Why no code was changed

### 1. The CDF formulas are correct — keep them (F1, F2, F3, F4)
I independently re-derived `d/dx _cdf` for all eleven `_cdf` methods and matched each to
the existing `pdf` (F1), and cross-checked the only non-elementary one, StudentT,
against the Cauchy special case where it must reduce to `1/2 + atan(x)/pi` (F2). The
required derivative rules (`lowergamma.fdiff`, `uppergamma.fdiff`,
`hyper._eval_derivative`) all exist, so the issue's recommended verification
(differentiate, compare to PDF, numerically) succeeds. All twelve documented examples
were traced to clean, terminating results (F4), including the specific Erlang
float-vs-exact complaint, which is resolved because `lowergamma(1,x)` auto-rewrites to
`1-exp(-x)` (F3). There is nothing to correct here.

### 2. The UniformSum hang is genuinely removed — keep V1 (F5, F6, F7)
This was the finding I most distrusted. `cdf()` applies `.doit()` to its result
(rv.py:760-763), so for UniformSum it forces evaluation of a `Sum` with a `floor(z)`
upper limit over a *symbolic* `z`. Crucially this is **not** the same path the
known-working PDF takes — `Density.doit` short-circuits and `__call__` returns the PDF
without `doit` (F6) — so I could not justify it by analogy and traced the summation
machinery directly: `floor(z)` is not an `Integer`, so `eval_sum` takes the symbolic
branch and runs only terminating algorithms (`apart`/`gosper_sum`/`eval_sum_hyper`) over
a finite expanded term set (F5). It terminates, returning either an unevaluated `Sum`
(which `doit`s correctly once the bound is concrete) or a closed form that is exact at
integer `floor(z)`. I also confirmed `.doit()` does not over-expand the special-function
CDFs — `hyper` reaches `hyperexpand` only via `expand`/`rewrite`/`evalf`, never `doit`
(F7) — so StudentT/Gamma/Nakagami/etc. are returned intact. Since the hang is removed
and the result is correct, V1's UniformSum (and StudentT) implementation stands.

### 3. The left-boundary edge cases do not warrant a change (F9, F10)
Frechet at exactly `x=m` and Dagum at exactly `x=0` can produce `nan`/`zoo` from
`0**(-a)` (F9). I deliberately did **not** tighten these to strict `>`:
- they are measure-zero points hit by none of the issue's examples and by no
  differentiation/numeric check (all use interior points);
- for the concrete positive parameters in the issue, Dagum at 0 already yields the
  correct `0`;
- inclusive `>=` boundaries are the module's established `_cdf` convention (Pareto
  `x>=xm`, ChiSquared/Exponential `x>=0`, Trapezoidal `x<=right`) (F10), and switching
  to `>` would both break that convention and risk mismatching any test that asserts the
  exact `Piecewise` structure.
The safer, convention-consistent choice is to keep `>=`.

### 4. No regressions to repair (F11, F12, F13, F14)
The review found nothing broken to fix: doctests on touched classes either use
`meijerg=True` (bypassing `_cdf`) or are `+SKIP`/pre-existing (F11); existing unit tests
pin Gamma's CDF via `meijerg` and the Uniform value test is unrelated (F12); `sample()`
was already non-functional for these distributions pre-fix, so nothing regresses and
some cases (Logistic) may now work (F13); characteristic function / moments never touch
`_cdf` (F14). With no regression, there is nothing to change.

### 5. Cosmetic items intentionally left alone (F15)
`S(x)` in the Gamma/Dagum `_cdf` and the standalone `from sympy import asin` line are
purely cosmetic: in the real call path `x` is always a `Dummy`, so `S(x)==x` with no
functional effect, and the separate import line matches the module's existing
multi-line import style (F15). Rewriting them would be churn against the
"keep the change minimal" guidance with zero behavioural benefit, and editing the
`cos, exp, besseli` line to fold in `asin` would touch code the fix does not otherwise
need to. Left unchanged.

## Net result
`review/FINDINGS.md` contains 15 findings; 13 are `[ok]`, 2 are `[minor]` (cosmetic /
non-attainable edge), and the single `[risk]` (F5) was resolved by code-tracing. None
requires a source change, so the V1 diff in `repo/sympy/stats/crv_types.py` is confirmed
as the final fix.
