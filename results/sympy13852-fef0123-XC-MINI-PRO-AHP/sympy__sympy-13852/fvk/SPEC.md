# SPEC.md — polylog evaluation (sympy/sympy#7132)

Target unit: `polylog` in `repo/sympy/functions/special/zeta_functions.py`
— specifically the construction path `polylog.eval` and the opt-in transform
`polylog._eval_expand_func`.

Formal core: [`mini-sympy.k`](mini-sympy.k) (fragment semantics) and
[`polylog-spec.k`](polylog-spec.k) (reachability claims). **Constructed, not
machine-checked.**

This is a symbolic-rewriting unit, not a counting loop, so the K model is a
small term-rewriting system: each `eval` / `expand_func` / `simplify` rule is a
rewrite, and a "contract" is a reachability claim `term ⇒ normal-form`. There is
no loop, hence no circularity obligation (noted in PROOF_OBLIGATIONS.md).

---

## 1. Intent-only obligations (INTENT_SPEC — written before trusting the code)

Derived purely from the public issue (`benchmark/PROBLEM.md`) and the in-repo
public test that cites the issue. Current/legacy behavior is recorded only as
"observed, to check," never as expected output.

- **I1 — dilog value exists.** `polylog(2, 1/2)` must yield the closed form
  `-log(2)**2/2 + pi**2/12`. *(prompt: "The answer should be …".)*
- **I2 — placement is the construction path.** The value is at a **specific,
  concrete argument** `(s=2, z=1/2)`, i.e. an intrinsic constant of the object;
  it must hold on the default/construction path with **no opt-in call**. The
  issue's `.expand(func=True)` and `nsimplify(expand_func(…).evalf(), …)` are the
  user's **workarounds** for the missing auto-evaluation; the bare unevaluated
  `polylog(2, 1/2)` in `In[1]`/`Out[1]` is the **symptom**, not a desired
  invariant. *(FVK output-form rule, corollaries (a)/(b).)*
- **I3 — no spurious `exp_polar`.** `expand_func(polylog(1, z))` must equal
  `-log(1 - z)` (a free-variable **symbolic identity**), with no
  `exp_polar(-I*pi)` factor. *(prompt: "I don't see a reason for exp_polar here …
  polylog(1, z) and -log(1-z) are exactly the same function".)*
- **I4 — derivative consistency.** After I3,
  `expand_func(diff(polylog(1, z) − expand_func(polylog(1, z)), z))` must reduce
  to `0`. *(prompt: the exp_polar form "changes the derivative".)*
- **I5 — downstream summation.** `Sum(1/(2**k*k**2), (k,1,oo)).doit().simplify()`
  must equal `-log(2)**2/2 + pi**2/12`. *(public test `test_R18`, `@XFAIL`,
  comment links issue #7132 — the fix is intended to land it.)*
- **I6 — family awareness.** "Add **evaluation** for polylog" names a *family*
  (special values of the polylog). The single shown member is `Li_2(1/2)`; other
  members are in scope for enumeration (Finding F4).

Default-domain assumptions, named: SymPy applies `Function.eval` at construction;
`expand_func` dispatches to `_eval_expand_func`; `simplify` is the pipeline in
`simplify.py` (no `expand_func` step); the principal branch is SymPy's default.

## 2. Public intent ledger

| # | Source | Quoted evidence | Obligation | Status (V2) |
|---|--------|-----------------|------------|-------------|
| L1 | prompt | "The answer should be `-log(2)**2/2 + pi**2/12`" | `polylog(2,1/2)` → that closed form | encoded — `eval-dilog`, claim EVAL-DILOG |
| L2 | prompt (form) + default-domain | `In[1]: polylog(2, Rational(1,2))` shown bare & unevaluated as the symptom; value only surfaced via `.expand(func=True)` workaround | specific-point constant ⇒ **construction path**, no opt-in call | encoded in `eval` (moved off `_eval_expand_func`) |
| L3 | prompt | "Why does the expansion of polylog(1, z) have exp_polar(-I*pi)? … exactly the same function" | `expand_func(polylog(1,z)) = -log(1-z)` | encoded — `expand-log1`, claim EXPAND-LOG1 |
| L4 | prompt | "expand_func changes the derivative … doesn't simplify to 0" | derivative consistency after L3 | encoded (derived in PROOF.md §D) |
| L5 | public-test `test_R18` | "`assert T.simplify() == -log(2)**2/2 + pi**2/12`" + "`# … issue/7132`", `@XFAIL` | `.doit().simplify()` reaches the value | encoded — claim SIMPLIFY-R18 |
| L6 | name/title | "**Add evaluation for polylog**" | family of special values | partial — F4 (Li_2(1/2) done; others = open Finding) |
| L7 | implementation | `simplify.py:556–620` has no `expand_func` call | simplify cannot reduce a bare polylog | used to justify L2/L5 placement |

**SUSPECT legacy displays (do not enshrine):** `Out[1] = polylog(2, 1/2)` and
`Out[2] = polylog(2, 1/2)` are the issue's *pre-fix* output — the reported
symptom. Per the SUSPECT rule they must **not** be read as "stays unevaluated by
default is the contract." `test_R18`'s `@XFAIL` is likewise the *pre-fix* status,
not a contract that it must keep failing.

## 3. FORMAL_SPEC_ENGLISH — English paraphrase of each K claim

- **EVAL-DILOG:** "Reducing the bare term `polylog(2, 1/2)` (no wrapper) reaches
  `pi^2/12 − log(2)^2/2`." ⇒ the value is on the construction path.
- **SIMPLIFY-R18:** "Reducing `simplify(doit(Σ (1/2)^k/k^2))` reaches
  `pi^2/12 − log(2)^2/2`." ⇒ holds *because* `doit` produces `polylog(2,1/2)`
  which the construction rule collapses before `simplify` (which has no expand
  step) sees it.
- **EXPAND-DILOG:** "Reducing `expand(polylog(2,1/2))` reaches the same closed
  form." ⇒ the `.expand(func=True)` surface from the issue still works (no
  regression), now because construction already reduced the object.
- **EXPAND-LOG1:** "Reducing `expand(polylog(1, Z))` for free `Z` reaches
  `−log(1 − Z)`." ⇒ no `exp_polar`; and because no `eval` rule matches a symbolic
  `z`, this stays a genuinely opt-in symbolic identity.

## 4. SPEC_AUDIT — formal-English vs intent

| Intent | Claim | Verdict |
|--------|-------|---------|
| I1 value | EVAL-DILOG | **pass** |
| I2 construction-path placement | EVAL-DILOG (bare term, no wrapper) | **pass** |
| I3 no exp_polar | EXPAND-LOG1 | **pass** |
| I4 derivative consistency | (derived, PROOF.md §D) | **pass** |
| I5 simplify/doit downstream | SIMPLIFY-R18 | **pass** |
| I6 family | — | **ambiguous/partial** → Finding F4 (Li_2(1/2) discharged; other members not cleanly derivable without references, deliberately not guessed) |
| (no-regression of issue workaround) | EXPAND-DILOG | **pass** |

No claim's English paraphrase merely restates a *legacy* output; the one place
V1 and V2 differ observably (SIMPLIFY-R18, EVAL-DILOG vs the bare symptom) is
resolved toward the **intent**, not toward the pre-fix display.

## 5. PUBLIC_COMPATIBILITY_AUDIT

Changed symbol: `polylog` — behavior of `polylog.eval` (now returns a value for
`(2, 1/2)`) and `polylog._eval_expand_func` (`s==1` → `-log(1-z)`; dilog case
removed from here).

- **Signature/return type:** unchanged. `eval` still returns either an `Expr` or
  `None`; `_eval_expand_func` still returns an `Expr`.
- **Callers of `_eval_expand_func`:** `lerchphi._eval_expand_func`
  (`zeta_functions.py:159`) calls `polylog(s, …)._eval_expand_func(**hints)` with
  **symbolic** `s` only → falls through to `return polylog(s, z)`; unaffected by
  the `s==1` / dilog changes. `expand_func` (core) dispatch unchanged.
- **Auto-evaluation reachability:** any construction of `polylog(2, Rational(1,2))`
  — direct, via `.subs`, or via `Sum.doit()` — now returns the closed form. No
  public callsite or in-repo test constructs that *specific* pair expecting a
  `polylog` instance: `test_args.py` uses `polylog(x, y)` (symbols);
  `test_hyperexpand.py` uses `polylog(2, z)` (symbol `z`). Searched: no breakage.
- **Branch/printing:** str form of the value is `-log(2)**2/2 + pi**2/12`
  (confirmed: it is the `print(...)` output quoted in PROBLEM.md line 14).

Result: **no unhandled public callsite or override.**
