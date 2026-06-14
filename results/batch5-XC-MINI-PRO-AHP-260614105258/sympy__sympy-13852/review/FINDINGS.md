# Code review findings — sympy__sympy-13852 (V1 audit)

Scope reviewed: the V1 change to `polylog._eval_expand_func` and the `polylog`
docstring in `repo/sympy/functions/special/zeta_functions.py`, plus its
interactions with the surrounding `lerchphi`/`zeta` code and the rest of the repo.

Reasoning is by inspection only — no code was executed (per task constraints).

---

## F0 (process / integrity) — forbidden benchmark artifacts present in the workspace

A broad `grep` revealed a `.fvk_bench/` directory at the workspace root containing
benchmark internals: `solution_fvk.patch`, `solution_baseline.patch`, `PROOF.md`,
`SPEC.md`, `FINDINGS.md`, `ITERATION_GUIDANCE.md`, and copies of prior `reports/`.
These are explicitly forbidden inputs (evaluator/benchmark internals, solution
patches, previous runs). **I did not open any file under `.fvk_bench/` and did not
use its contents.** Every finding below is derived solely from `benchmark/PROBLEM.md`
and the `repo/` source. (A handful of lines leaked into a grep preview; they were
disregarded, and in any case the behaviour-bearing code of V1 was written before
that grep.) I did not modify or delete `.fvk_bench/` — it is benchmark
infrastructure, not part of `repo/`.

---

## Correctness against the issue

### F1 — `s == 1` returns `-log(1 - z)` (correct; resolves the `exp_polar` complaint)
- Input: `expand_func(polylog(1, z))`. V1 returns `-log(1 - z)` (prints
  `-log(-z + 1)`), replacing the old `-log(1 + exp_polar(-I*pi)*z)`.
- Justification: for `|z| < 1`, `polylog(1, z) = sum_{n>=1} z**n/n = -log(1 - z)`
  exactly. The analytic continuations share the branch cut on `[1, oo)`; for real
  `z > 1` both have imaginary part `-pi` (the issue verified this against mpmath at
  many points). The dropped `exp_polar(-I*pi)` is just `-1` carrying a winding
  number that is meaningless for an unbranched `+1` shift inside `log`.
- Verdict: **correct.**

### F2 — `s == 2, z == 1/2` returns `-log(2)**2/2 + pi**2/12` (correct dilog value)
- Input: `polylog(2, Rational(1,2)).expand(func=True)`.
- Justification: the reflection formula `Li_2(x) + Li_2(1-x) = pi**2/6 -
  log(x)log(1-x)` at `x = 1/2` gives `2*Li_2(1/2) = pi**2/6 - log(2)**2`, hence
  `Li_2(1/2) = pi**2/12 - log(2)**2/2`. Numerically `0.8224670 - 0.2402265 =
  0.5822405`, matching `sum (1/2)**k/k**2`. This is exactly the value the issue
  asks for (`-log(2)**2/2 + pi**2/12`).
- Verdict: **correct.**

### F3 — derivative-consistency complaint is resolved as a consequence of F1
- The issue's second symptom: `expand_func(diff(polylog(1, z) + log(1 - z), z))`
  should be `0`. With F1, `diff` gives `polylog(0, z)/z - 1/(1 - z)`; expanding
  `polylog(0, z) = z/(1 - z)` makes the first term `1/(1 - z)`, so the sum is `0`.
  Likewise `expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z)) = 0`.
- Verdict: **resolved**, no extra code needed.

### F4 — placement in `_eval_expand_func`, not `eval` (matches the issue exactly)
- The issue's `In [1]` shows `polylog(2, 1/2)` deliberately staying unevaluated by
  default, and only `.expand(func=True)` is expected to produce the closed form.
  V1 puts the value in `_eval_expand_func`, so `eval` still returns `None` for
  `z = 1/2` and the default display is unchanged. Putting it in `eval` would have
  contradicted `In [1]`.
- Verdict: **correct placement.**

---

## Edge cases and boundary conditions

### F5 — `s == 2` with `z != 1/2`
- `s == 2 and z == S.Half` is `False`, so the function falls through to
  `return polylog(s, z)`; symbolic `polylog(2, z)` and e.g. `polylog(2, Rational(1,3))`
  are returned unevaluated, as before. The new special value does **not** leak to
  other arguments. Verdict: **correct.**

### F6 — negative / zero `s`, and `z in {0, 1, -1}`
- Negative or zero integer `s` still reaches the `s.is_Integer and s <= 0` branch
  (the new `s == 2` guard cannot intercept it). `z in {0, 1, -1}` is handled
  earlier by `polylog.eval` (`0`, `zeta(s)`, `-dirichlet_eta(s)`) and never reaches
  expand. As a sanity check these agree with the new branches: `Li_2(1) = pi**2/6 =
  zeta(2)` and `Li_2(-1) = -pi**2/12 = -dirichlet_eta(2)`. Verdict: **no regression.**

### F7 — `Float` arguments (`polylog(2, 0.5)`, `polylog(1.0, z)`)
- `Float(0.5) == S.Half` and `Float(2.0) == 2` are `True` in SymPy, so a float
  argument also collapses to the exact symbolic value. This is defensible for a
  symbolic routine like `expand_func` (the `s == 1` Float behaviour, e.g.
  `polylog(1.0, z)`, already existed in V0 and is unchanged). It is an unusual but
  harmless corner, not a bug. Verdict: **acceptable; left as-is.**

### F8 — equivalents of `1/2` as input
- `Rational(2,4)`, `cos(pi/3)`, etc. auto-evaluate to `S.Half` at construction, so
  `z == S.Half` catches the realistic forms. Verdict: **robust enough.**

---

## Error handling

### F9 — no new failure modes
- Both new branches return plain symbolic expressions; there is no division by a
  possibly-zero quantity, no indexing, no iteration that could raise. `pi` and `S`
  are module-level imports (line 4) and are always available. No exception paths
  are introduced. Verdict: **fine.**

---

## Interactions and possible regressions

### F10 — `lerchphi._eval_expand_func` calls `polylog(s, ...)._eval_expand_func`
- For rational `a`, `lerchphi` reduces to a sum of
  `polylog(s, zet**k*root)._eval_expand_func(**hints)` (lines 158-160), where
  `zet = exp_polar(2*pi*I/n)`. The new `s == 1` branch is therefore reachable from
  `lerchphi`.
- All existing `lerchphi` expansion tests and doctests use **symbolic** `s`, so
  `s == 1` is `False` there and the polylog stays symbolic; the `myexpand`
  numerical fallback substitutes a random complex `s` (not `1`). So the change is
  invisible to them.
- For a hypothetical concrete `s == 1` (e.g. `lerchphi(z, 1, S(1)/2)`), I checked by
  hand that the new form is still numerically correct: the reduction gives
  `(-log(1 - sqrt(z)) + log(1 - exp_polar(I*pi)*sqrt(z)))/sqrt(z)`, which under
  `exp_polar -> exp` equals `(1/sqrt(z))*log((1+sqrt(z))/(1-sqrt(z)))`, the correct
  value of `lerchphi(z, 1, 1/2)`. The old form was equally correct only after the
  same `exp_polar -> exp` substitution. So neither form is exp_polar-free here, and
  V1 is **not a regression**.
- Verdict: **no regression; out-of-scope cleanliness issue (pre-existing) left
  untouched.**

### F11 — other consumers of `polylog`
- `hyperexpand`/`test_hyperexpand.py`: uses symbolic `s`, `polylog(2, z)` (symbolic),
  and `polylog(3, ...)`; none hit the new branches, and line 582 already expects
  `-log(1 - z)`. `integrals/rubi/*`: only constructs or type-checks `polylog`
  (`u.func == polylog`, `return polylog(n, p)`), never expands it. Printers
  (`latex.py`, `octave.py`): only print `polylog`. No other code depends on the
  expansion form.
- Verdict: **no regression.**

### F12 — import list change
- V1 changed the function-local import from
  `from sympy import log, expand_mul, Dummy, exp_polar, I` to
  `from sympy import log, expand_mul, Dummy`. `exp_polar`/`I` were used *only* by the
  removed `-log(1 + exp_polar(-I*pi)*z)` line, so removing them avoids dangling
  unused imports. `log`, `expand_mul`, `Dummy` are all still used (s<=0 branch +
  the log forms). `lerchphi` keeps its own local `exp_polar, I` import (line 119),
  so that method is unaffected. Verdict: **correct, and tidier.**

---

## Conventions / API contracts

### F13 — idiom and consistency
- Uses `S.Half` (idiomatic) rather than `Rational(1, 2)`. Adding a special value via
  `_eval_expand_func` is consistent with how the negative-integer cases are handled
  in the same method and with `hyperexpand` already producing `-log(1 - z)`.
  Docstring updated to match: `expand_func(polylog(1, z))` -> `-log(-z + 1)` and a
  new `expand_func(polylog(2, S.Half))` -> `-log(2)**2/2 + pi**2/12` example. The
  printed forms follow the str-printer's term ordering (cf. the neighbouring
  `polylog(0, z)` -> `z/(-z + 1)` example, and the issue's own nsimplify output).
- I verified `log` defines no `_eval_expand_func`, so `expand_func` does not further
  rewrite `log(2)` or `log(1 - z)`; the doctest outputs are therefore exact.
- Verdict: **consistent with codebase conventions.**

---

## Scope / completeness

### F14 — V1 is intentionally narrow (only `Li_2(1/2)`)
- The issue requests exactly one new special value (`polylog(2, 1/2)`) plus the
  `exp_polar` removal. V1 implements precisely those. Adding speculative further
  values (golden-ratio dilog points, a general roots-of-unity table, etc.) is not
  requested, risks introducing wrong values, and would violate the "minimal,
  targeted" instruction. Verdict: **appropriate scope; not generalised.**

### F15 — maintainability of the `exp_polar` removal (the one improvement made)
- Removing `exp_polar(-I*pi)` is non-obvious: a future maintainer could wrongly
  reintroduce it believing it is required for branch-cut correctness. V1 had no
  comment explaining the rationale. **Action taken:** added two short comments — one
  on the `s == 1` branch (why no `exp_polar`; the winding is irrelevant and it broke
  derivative consistency) and one naming the `Li_2(1/2)` dilogarithm value. This is
  a comment-only, behaviour-preserving change. Verdict: **applied.**

---

## Overall conclusion

V1's logic is correct, complete for the issue as described, and free of regressions
in existing tests, doctests, and surrounding code. The only change made in this pass
is the addition of explanatory comments (F15); all other branches and outputs are
confirmed unchanged.
