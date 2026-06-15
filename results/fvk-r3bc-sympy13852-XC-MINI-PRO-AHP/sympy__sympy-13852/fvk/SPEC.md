# SPEC.md — `polylog` (sympy issue 13852)

Human-readable specification + public-intent ledger + adequacy audit for the
fix. The formal claims live in [`polylog-spec.k`](polylog-spec.k) over
[`mini-sympy.k`](mini-sympy.k). Everything here is **constructed, not
machine-checked** (no execution environment).

Unit under audit: `sympy/functions/special/zeta_functions.py`, class `polylog`
— the classmethod `eval` and the method `_eval_expand_func`. Both are
*contributors to the same observable* ("what does `polylog(s, z)` reduce to,
and when?"), so they are specified together (formalize.md Step 2: trace every
contributor to the observable).

---

## 1. INTENT_SPEC (intent-only — written before trusting any current behavior)

Derived from the public issue (`benchmark/PROBLEM.md`), the `polylog` docstring,
the established dilogarithm special values, and named default-domain
conventions. Current/legacy behavior is recorded as *observed*, never as
expected-by-itself.

- **I1 — Dilogarithm value at 1/2.** `polylog(2, 1/2)` must be obtainable as the
  closed form `-log(2)**2/2 + pi**2/12` (= `Li_2(1/2) = pi**2/12 - log(2)**2/2`).
  *Evidence:* issue title "Add evaluation for polylog"; "The answer should be
  `-log(2)**2/2 + pi**2/12`".
- **I2 — Placement of I1 is the default/construction path.** The desired value
  is the value of the **bare** object `polylog(2, Rational(1,2))`. The issue's
  `Out[1]: polylog(2, 1/2)` (unevaluated) is the reported **symptom**, not a
  contract to preserve. *Evidence:* output-form rule (intent-evidence.md §3,
  formalize.md Step 2, verify.md Step 2) — a value shown bare sets a placement
  obligation on `eval`/constructor; and the methodology names *this very case*:
  "An issue whose reproduction shows `polylog(2, 1/2)` printing unevaluated is
  reporting that as the symptom — do not enshrine 'stays unevaluated by default'
  as an invariant." Default-domain: special values auto-evaluate in `eval`
  (cf. `zeta(2)`, `dirichlet_eta(2)`).
- **I3 — `expand_func(polylog(1, z)) = -log(1 - z)`, no `exp_polar`.** For all
  `z`. *Evidence:* "polylog(1, z) and -log(1-z) are exactly the same function
  ... I don't see a reason for exp_polar here"; mpmath agreement; the `exp_polar`
  winding is about `z=0`, irrelevant to a function branched only at `z=1`.
- **I4 — Derivative consistency under I3.** `expand_func(diff(polylog(1, z) -
  expand_func(polylog(1, z)), z))` must be `0`. *Evidence:* issue body. (With
  `-log(1-z)`: `d/dz polylog(1,z) = polylog(0,z)/z = (z/(1-z))/z = 1/(1-z)` and
  `d/dz(-log(1-z)) = 1/(1-z)`.)
- **I5 — Preserve existing special-z evaluations.** `polylog(s,0)=0`,
  `polylog(s,1)=zeta(s)`, `polylog(s,-1)=-dirichlet_eta(s)`. *Evidence:*
  docstring + `test_polylog_expansion`.
- **I6 — Preserve the integer `s<=0` elementary reductions.**
  `expand_func(polylog(0,z)) = z/(1-z)`, `polylog(-1,z)=…`, etc. *Evidence:*
  docstring + `test_polylog_expansion`.
- **I7 — No spurious construction-time evaluation.** `polylog(s, z)` with
  symbolic `z` (and non-special `s`) stays a live symbolic object. *Evidence:*
  `test_derivatives` `td(polylog(b, z), z)`, rewrite/series usage.
- **I8 — Family completeness (dilogarithm special values).** I1 is one member of
  the known `Li_2` special-value table. Enumerate the table; handle the members
  intent/established-references justify; record the rest as open Findings (do
  not invent). *Evidence:* family/table-completeness rule (formalize.md Step 2).

Default-domain assumptions (named): standard sympy `log` branch; `eval` is the
auto-evaluation entry point; `range(-s)` iterates `max(0,-s)` times.

---

## 2. Public-intent ledger

| # | Source | Quoted evidence | Semantic obligation | Status in V2 |
|---|--------|-----------------|---------------------|--------------|
| L1 | prompt | "The answer should be `-log(2)**2/2 + pi**2/12`" | `polylog(2,1/2)` value = that closed form | **encoded** (eval-half) |
| L2 | prompt (form) + method doc | bare `polylog(2, Rational(1,2))`; "do not enshrine 'stays unevaluated' as an invariant" | value lands on **construction/eval** path | **encoded** (moved to `eval`) — was the V1 defect |
| L3 | prompt | "I don't see a reason for exp_polar here … exactly the same function" | `expand_func(polylog(1,z)) = -log(1-z)` | **encoded** (expand-s1) |
| L4 | prompt | "expand_func(diff(polylog(1,z) - expand_func(polylog(1,z)), z))" ⇒ 0 | derivative consistency | **holds** (see I4) |
| L5 | docs + public-test | "For z in {0,1,-1} … automatically expressed" | preserve special-z evals | **preserved** (eval-z1/zm1/z0) |
| L6 | docs + public-test | `myexpand(polylog(0,z), z/(1-z))` etc. | preserve `s<=0` reductions | **preserved** (expand-nonpos, LOOP) |
| L7 | public-test | `td(polylog(b, z), z)` | symbolic polylog stays live | **preserved** (eval-sym-frame) |
| L8 | **SUSPECT** pre-fix display | `Out[1]: polylog(2, 1/2)`, `Out[2]: polylog(2, 1/2)` | (would say "stays unevaluated") | **rejected as oracle** — it is the reported symptom (L2) |
| L9 | domain reference | MathWorld/Wikipedia dilog table | other `Li_2` special values | **open Finding** (F3); not invented |

---

## 3. FORMAL_SPEC_ENGLISH (paraphrase of every claim in `polylog-spec.k`)

- **(EVAL-HALF)** Building `polylog(2, 1/2)` rewrites — in one construction step,
  no opt-in transform — to `-log(2)**2/2 + pi**2/12`.
- **(EVAL-HALF-COROLLARY)** That construction never leaves the term as a
  symbolic `polylog(2, 1/2)` (the closed form ≠ the symbolic polylog).
- **(EVAL-Z1/ZM1/Z0)** Building `polylog(s, 1)` → `zeta(s)`; `polylog(s, -1)` →
  `-dirichlet_eta(s)`; `polylog(s, 0)` → `0`.
- **(EVAL-SYM-FRAME)** Building `polylog(s, z)` with symbolic `z` → the symbolic
  `polylog(s, z)` (no evaluation).
- **(EXPAND-S1)** `expand_func(polylog(1, z))` → `-log(1 - z)` (no `exp_polar`).
- **(EXPAND-S0)** `expand_func(polylog(0, z))` → `(u/(1-u))` with `u:=z`
  (= `z/(1-z)`), via zero loop iterations.
- **(EXPAND-SYM-FRAME)** `expand_func(polylog(s, z))` with symbolic order `s` →
  the symbolic `polylog(s, z)` unchanged.
- **(LOOP)** For every `N >= 0`, the loop `runTheta(N, acc)` terminates and
  performs exactly `N` applications of `theta` (= `thetaPow(N, acc)`).

---

## 4. SPEC_AUDIT (formal-English vs INTENT_SPEC)

| Claim | Maps to intent | Verdict | Note |
|-------|----------------|---------|------|
| EVAL-HALF | I1, I2 | **pass** | value (I1) on the construction path (I2). Independent provenance: prompt value + bare-form placement rule, not "what the code emits". |
| EVAL-HALF-COROLLARY | I2 | **pass** | formalizes "do not enshrine stays-unevaluated". |
| EVAL-Z1/ZM1/Z0 | I5 | **pass** | unchanged legacy that *does* have docs+test intent. |
| EVAL-SYM-FRAME | I7 | **pass** | needed so I1 does not over-fire to symbolic z. |
| EXPAND-S1 | I3, I4 | **pass** | `-log(1-z)`; derivative-consistency (I4) checked separately, holds. |
| EXPAND-S0 | I6 | **pass** | unchanged legacy with docs+test intent. |
| EXPAND-SYM-FRAME | I3 (no exp_polar leaks) | **pass** | confirms no `exp_polar` anywhere now. |
| LOOP | I6 | **pass (shallow)** | termination + iteration count only; the branch is unchanged. Not a deep arithmetic identity — stated honestly. |
| Family I8 | I8 | **ambiguous/open** | only `1/2` handled; rest routed to Findings F3 (not invented). Does **not** justify "fix is done" by itself. |

**Coincidence check (intent-evidence.md §4).** EVAL-HALF's value equals what V2's
code now emits — but its provenance is the prompt's stated answer + the
established `Li_2(1/2)` identity + the bare-form placement rule, all independent
of the implementation. EXPAND-S1's value is the prompt's own assertion. Neither
postcondition merely restates code output to certify it.

**Soundness vs completeness (verify.md Step 1).** The claims are *sound* over
what they state. They do **not** by themselves prove the whole intent is met:
I8 (family) is only partially covered — see Findings. The proof's green status is
necessary, not sufficient.

---

## 5. PUBLIC_COMPATIBILITY_AUDIT

Changed symbols: `polylog.eval` (added one `(s,z)` case) and
`polylog._eval_expand_func` (changed the `s==1` result; removed the `(2,1/2)`
case it temporarily held in V1). No signature, arity, or return-type change.

| Concern | Finding |
|---------|---------|
| Public callsites of `polylog(2, S.Half)` expecting an unevaluated polylog | none found (repo-wide search: only docstring + the public test mention `polylog(1, z)` / the expansion). |
| Code matching the old `expand_func(polylog(1, z))` shape `-log(... exp_polar ...)` | none in non-test source/docs; `hyperexpand`/`meijerint` use `exp_polar(-I*pi)*z` inside `meijerg`/`hyper`, unrelated to this reduction. |
| `lerchphi._eval_expand_func` calls `polylog(s, …)._eval_expand_func()` | for `s==1` it now gets `-log(1-…)` instead of the `exp_polar` form — a consistent improvement, still numerically equal; for general `s` it is unaffected. |
| Subclasses/overrides of `polylog` | none in repo. |
| `eval` now intercepts `polylog(2, S.Half)` before `_eval_expand_func` | intended (L2); `_eval_expand_func` therefore never sees `plog(2, 1/2)`, so removing its V1 case is safe (dead after the move). |

No unhandled public callsite or override. Compatibility: **OK.**
