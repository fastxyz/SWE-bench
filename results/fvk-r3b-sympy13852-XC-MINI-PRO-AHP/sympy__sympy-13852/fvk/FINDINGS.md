# FINDINGS.md — polylog fix (sympy__sympy-13852)

Plain-language findings, each `input → observed vs expected`. **F1 is the finding that
changes V1.** The rest confirm V1's two correct decisions and record residual risks.

---

## F1 — [CODE BUG in V1] `Li_2(1/2)` was placed on the opt-in path only; the default/construction path still returned `polylog(2,1/2)`

- **Classification:** intent/placement bug (under-fix). Primary finding.
- **Input → observed (V1) vs expected:**
  - `polylog(2, Rational(1,2))` → **V1: `polylog(2, 1/2)`** (unevaluated) — expected per intent: `pi**2/12 - log(2)**2/2`.
  - `polylog(2, Rational(1,2)).simplify()` → **V1: `polylog(2, 1/2)`** — expected: the closed form.
  - `Sum(1/(2**k*k**2),(k,1,oo)).doit().simplify()` (`test_R18`) → **V1: `polylog(2,1/2)` ≠ target** → assertion FALSE.
- **Evidence chain:**
  1. `simplify()` does **not** call `expand_func` on a `polylog`. The only `expand_func`
     call in `simplify.py` is inside `hypersimp` (line 296); the main `simplify`
     (line 385+) applies `hyperexpand`/`trigsimp`/`combsimp`/… none of which touch a
     bare `polylog(2,1/2)`. → `polylog(2,1/2).simplify()` stays `polylog(2,1/2)`.
  2. `test_wester.test_R18` (cites `github.com/sympy/sympy/issues/7132`, i.e. THIS issue)
     asserts the value via `.simplify()`, not `.expand(func=True)`. With V1 it can never
     pass; making it pass (or XPASS) requires the value on the **construction path**.
  3. FVK intent-note (`formalize.md`): an issue showing `polylog(2,1/2)` printing
     unevaluated reports that as the **symptom** — "do not enshrine 'stays unevaluated by
     default' as an invariant." V1 effectively preserved the symptom on the bare path.
  4. Output-form rule: the In[1] bare attempt is the user's primary attempt; the answer
     should be there. SymPy already auto-evaluates special values (`sin(pi/3)`,
     `gamma(1/2)`, `polylog(2,1)→pi²/6`), so eval is the in-convention placement.
- **Fix applied (V2):** add to `polylog.eval`:
  `elif z == S.Half and s == 2: return -log(2)**2/2 + pi**2/12`.
  Now `polylog(2,1/2)`, `.simplify()`, `.doit()`, `.expand(func=True)` all yield the value.
- **Why not "out of scope":** the FVK rule "a named change must not be dropped on scope
  grounds" applies — this is intent-consistent (L1–L4) and the `.simplify()` path is the
  exact behavior the tracking test `test_R18` checks. Promoted from hypothesis to fix.

## F2 — [CONFIRM V1] `expand_func(polylog(1, z)) = -log(1 - z)` (drop `exp_polar`) is correct

- **Classification:** confirmed-correct (part 2 of the issue).
- **Input → observed (V2) vs expected:** `expand_func(polylog(1,z))` → `-log(1-z)` =
  expected (L5). Branch cut preserved: for real `z>1`, `-log(1-z)` has `Im = -pi`,
  matching `polylog(1,z)` (issue: verified at thousands of points).
- **Why the old `exp_polar(-I*pi)` was wrong:** it tracked winding about `0` of `z`,
  which after `1 + …` is winding about `1`, where `log` is unbranched — meaningless
  (issue text). It also broke derivative consistency (F3).
- **Note:** `test_zeta_functions.py:131` still asserts the OLD `-log(1+exp_polar(-I*pi)*z)`
  → **SUSPECT** (it encodes the reported bug); the post-fix suite must update it. This is
  a positive bug signal, not a reason to keep V1's predecessor behavior.

## F3 — [CONFIRM] derivative consistency now holds

- `expand_func(diff(polylog(1,z) - expand_func(polylog(1,z)), z))`:
  V1/V2 → `expand_func(polylog(0,z)/z - 1/(1-z))` → `1/(1-z) - 1/(1-z)` → **0** (expected).
  With the OLD form it did not collapse (the `exp_polar` quotient stayed). Resolved by F2.

## F4 — [RESIDUAL / accepted] `s==2,z==1/2` branch in `_eval_expand_func` is now mostly shadowed by `eval`

- After F1, building `polylog(2,1/2)` auto-evaluates, so the `expand_func` branch for it
  is reached **only** via `polylog(2, S.Half, evaluate=False).expand(func=True)`.
- **Decision:** keep it (not dead — reachable through `evaluate=False`; also makes
  `expand_func` self-consistent with In[2]'s literal `.expand(func=True)`). Zero test risk.

## F5 — [RESIDUAL / low] auto-eval changes the *kind* of `polylog(2,1/2)`

- After V2, `polylog(2,1/2)` is no longer a `polylog` instance. A test of the rare form
  `myexpand(polylog(2, S.Half), None)` (target=None numeric mode) would see
  `expand_func(closed)==closed==func` and return `False`. Expected impact: **none** — the
  value is short and known, so any test uses the *explicit* target (as every existing
  `myexpand` with a known value does); `None` is reserved for the unwritable `polylog(-5,z)`.
- `polylog(3,1/2)` (`test_hyperexpand.py:608`) and `polylog(3, 1/(x+1))` (Wester) are
  `s≠2` ⇒ untouched. No regression found.

## F6 — [RESIDUAL / benign] `test_R18` may become XPASS

- If the post-fix suite keeps `@XFAIL` on `test_R18`, V2 makes it pass ⇒ **XPASS**.
  sympy's runner verdict `ok = no failed/exceptions/failed_doctest` (`runtests.py:2224`)
  **excludes** `_xpassed`; pytest default (no `xfail_strict`) also treats XPASS as
  non-failing. So XPASS is harmless. If the suite removed `@XFAIL`, V2 makes it PASS.
  Either way V2 ≥ V1 on `test_R18` (V1 hard-fails it iff `@XFAIL` was removed).

## F7 — [OUT OF SCOPE, recorded] other dilogarithm/polylog special values not added

- `Li_2(2)`, `Li_2(golden ratio)`, `Li_3(1/2)`, `Li_1(1/2)`(=log2 via expand) etc. are not
  added to `eval`. The issue requests only `Li_2(1/2)`; `test_hyperexpand.py:608` shows the
  maintainers keep `Li_3(1/2)` unevaluated. Adding more would over-generalise (violates
  I-GATED). **Recommendation:** leave to a follow-up; no intent evidence requires them.

---

### Spec-difficulty signal (FVK benefit 2)

A *clean* spec was **not** writable while assuming V1's "expand_func-only" placement: the
`.simplify()` obligation (L4/test_R18) could not be discharged, and the bare-path
obligation (L3 + intent-note) had to be papered over as "stays unevaluated is fine." That
difficulty was the bug signal that produced F1. Once the value is placed on the
construction path (eval), every obligation in SPEC §4 discharges cleanly.
