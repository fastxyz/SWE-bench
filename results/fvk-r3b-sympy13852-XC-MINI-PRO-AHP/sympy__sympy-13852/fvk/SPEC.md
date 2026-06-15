# SPEC.md — formal specification for the `polylog` fix (sympy__sympy-13852)

Targets audited: `sympy/functions/special/zeta_functions.py`
- `polylog.eval(cls, s, z)` — construction-time auto-evaluation
- `polylog._eval_expand_func(self, **hints)` — closed-form expansions
- `polylog.fdiff` — derivative (unchanged; used by an obligation)

Formal core: [`mini-cas.k`](mini-cas.k) (semantics fragment) and
[`polylog-spec.k`](polylog-spec.k) (K reachability claims). Status: **constructed,
not machine-checked** (no execution environment; `kompile`/`kprove` not run).

---

## 1. Public intent ledger

Evidence is public only: the issue text (`benchmark/PROBLEM.md`), in-repo docstrings,
and in-repo tests. Per FVK, in-repo tests and the issue's "before" REPL outputs are
**evidence, not an oracle**; a "before" display of the reported bug is **SUSPECT**.

| # | Source | Quoted evidence | Semantic obligation | Status |
|---|--------|-----------------|---------------------|--------|
| L1 | prompt (title) | "Add evaluation for polylog" | `polylog(2,1/2)` must yield its closed value | encoded (eval) |
| L2 | prompt | "The answer should be `-log(2)**2/2 + pi**2/12`" (shown after `In[2]: ...expand(func=True)`) | the closed value is `pi²/12 − log²2/2`; obtainable via `expand_func` | encoded (eval + expand) |
| L3 | prompt | `In [1]: polylog(2, Rational(1,2))` → `polylog(2, 1/2)` | **SUSPECT** "before" display of the bug (the symptom: it does not evaluate). Do **not** enshrine "stays unevaluated by default". | drives eval |
| L4 | public-test | `test_wester.test_R18` (`@XFAIL`, cites `issues/7132`): `Sum(1/(2**k*k**2),(k,1,oo)).doit()` then `assert T.simplify() == -log(2)**2/2 + pi**2/12` | the value must be reachable through **`.simplify()`/`.doit()`**, not only `expand_func` | encoded (eval) |
| L5 | prompt | "polylog(1, z) and -log(1-z) are exactly the same function for all purposes … exp_polar … is just not meaningful" | `expand_func(polylog(1,z)) = -log(1-z)` (no `exp_polar`) | encoded (expand, s=1) |
| L6 | prompt | "`expand_func(diff(polylog(1, z) + log(1 - z), z))  # 0`" and that the old form's derivative did **not** collapse to 0 | `polylog(1,z) ≡ -log(1-z)` incl. derivative; the consistency check must give `0` | encoded (consequence of L5) |
| L7 | docs (docstring) | `>>> expand_func(polylog(1, z))` example | the doctest output must match the new result `-log(-z + 1)` | encoded (docstring) |
| L8 | public-test | `test_hyperexpand.py:608` `polylog(3, S(1)/2)` and `test_wester.py:1953` "returns polylog(2, 1/2)" | polylog at `1/2` for `s≠2` stays an unevaluated object (no closed form added) | respected (eval gated on `s==2`) |
| L9 | name/convention | `sin(pi/3)→sqrt(3)/2`, `gamma(1/2)→sqrt(pi)`, `polylog(2,1)→pi²/6` | auto-evaluating a special value to a closed (even transcendental) form is the SymPy norm | supports eval |

Provenance labels: L1,L2,L5,L6 `intent-derived`; L3 `SUSPECT legacy-display`;
L4,L8 `public-test`; L7 `docs`; L9 `default-domain-convention`.

## 2. INTENT_SPEC (intent-only English, written before trusting any candidate)

1. **I-VALUE.** `polylog(2, 1/2)` denotes `pi**2/12 - log(2)**2/2`. The system must
   deliver this value. (L1, L2, L9)
2. **I-DEFAULT.** "Add evaluation" + the SUSPECT bare display (L3) + the `.simplify()`
   test (L4): the value must hold on the **default/construction path**, so that
   `polylog(2,1/2)`, `.simplify()`, `.doit()`, and `.expand(func=True)` all yield it.
   *Do not* relocate the obligation onto `expand_func` alone while the default path
   keeps returning `polylog(2,1/2)`.
3. **I-GATED.** Only the `s=2`, `z=1/2` case has a closed form added; `polylog(3,1/2)`
   etc. remain unevaluated objects (L8). No over-generalisation.
4. **I-LI1.** `expand_func(polylog(1, z)) = -log(1 - z)` exactly, with no `exp_polar`
   factor, for symbolic `z`. (L5)
5. **I-DERIV.** Because `polylog(1,z) ≡ -log(1-z)`, expanding must not change the
   derivative: `expand_func(diff(polylog(1,z) - expand_func(polylog(1,z)), z)) = 0`. (L6)
6. **I-DOCTEST.** The docstring example for `expand_func(polylog(1,z))` prints
   `-log(-z + 1)`. (L7)
7. **I-REGRESS.** `polylog(s,0)=0`, `polylog(s,1)=zeta(s)`, `polylog(s,-1)=-dirichlet_eta(s)`
   unchanged; symbolic `polylog(s,z)` and `s≤0` expansion unchanged.

## 3. FORMAL_SPEC_ENGLISH (English paraphrase of each K claim)

- **(EVAL-HALF)** building `polylog(2, 1/2)` rewrites to `pi²/12 − log²2/2`. ⇒ I-VALUE, I-DEFAULT.
- **(SIMPLIFY-HALF)** `simplify(polylog(2,1/2))` reaches `pi²/12 − log²2/2`; only possible
  because construction already produced the closed form (simplify is the identity on a
  bare polylog). ⇒ I-DEFAULT, L4.
- **(EXPAND-HALF)** `expand_func(polylog(2,1/2))` reaches `pi²/12 − log²2/2`. ⇒ I-VALUE (In[2]).
- **(EXPAND-LI1)** `expand_func(polylog(1,z))` reaches `-log(1-z)` (no `exp_polar`). ⇒ I-LI1.
- **(DERIV-CONSISTENT)** `expand_func(d/dz(polylog(1,z) − expand_func(polylog(1,z))))` reaches `0`. ⇒ I-DERIV.
- **(EVAL-PRESERVED)** `z∈{1,-1,0}` still rewrite to `zeta(s)`, `-dirichlet_eta(s)`, `0`. ⇒ I-REGRESS.

## 4. SPEC_AUDIT (formal-English vs INTENT_SPEC)

| Obligation | Claim(s) | Verdict |
|---|---|---|
| I-VALUE | EVAL-HALF, EXPAND-HALF | **pass** — value entailed by L1/L2/L9 |
| I-DEFAULT | EVAL-HALF, SIMPLIFY-HALF | **pass** — bare/simplify/doit path; entailed by L3 (SUSPECT⇒not-enshrine) + L4 |
| I-GATED | EVAL-HALF (`s==2` guard) | **pass** — L8 respected; `polylog(3,1/2)` untouched |
| I-LI1 | EXPAND-LI1 | **pass** — L5 verbatim |
| I-DERIV | DERIV-CONSISTENT | **pass** — L6; needs cancellation VC + LEM-LI1 |
| I-DOCTEST | (docstring text) | **pass** — `-log(-z + 1)` is the printed form (cf. `polylog(0,z)→z/(-z+1)`) |
| I-REGRESS | EVAL-PRESERVED | **pass** — branches unchanged |

No `fail`/`ambiguous` rows. The one resolved tension — *placement* (eval vs
expand_func) — is decided **toward eval** by L3+L4 (not toward the candidate V1); see
FINDINGS F1. The transcendental targets (LEM-LI1, LEM-LI2) are correct-but-
beyond-tier ⇒ `[ESCALATION BOUNDARY]` in PROOF.md, not a spec failure.

## 5. PUBLIC_COMPATIBILITY_AUDIT

Changed public-observable behavior of `polylog`:

| Change | Public callsites / overrides searched | Status |
|---|---|---|
| `polylog(2, Rational(1,2))` now auto-evaluates (eval) | `repo` grep `polylog(…1/2…)`: `test_wester.py:1953` (R18, **benefits** — its pipeline now closes), `test_hyperexpand.py:608` uses `polylog(3, …)` (s=3, **unaffected**). No production callsite constructs `polylog(2,1/2)` expecting an object. | safe |
| `expand_func(polylog(1,z))` → `-log(1-z)` (was `-log(1+exp_polar(-I*pi)*z)`) | only consumer of `polylog(1,·)` expansion is `lerchphi._eval_expand_func` (symbolic `s` ⇒ branch not hit) and the docstring (updated). `test_zeta_functions.py:131` encodes the OLD form ⇒ **SUSPECT** (it is the reported bug) ⇒ the post-fix suite must update it. | safe (test is SUSPECT) |
| removed unused `exp_polar, I` from a local import | none | safe |

No public signature, return-type, or dispatch change. `polylog.fdiff`, `_eval_rewrite_as_lerchphi`, and the `s≤0` expansion are untouched.

## 6. Trusted base / residual risk

mini-cas.k faithfully mirrors the four SymPy methods as rewrite rules but abstracts the
full CAS arithmetic normaliser; the reachability metatheory + `kprove` are trusted but
**not run here**; LEM-LI1/LEM-LI2 are special-function identities routed to references
(see PROOF.md §escalation). Partial-correctness only (no termination claim; the only
loop, the `s≤0` `for _ in range(-s)` expansion, is unchanged by the fix and out of scope).
