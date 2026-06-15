# FINDINGS.md — polylog fix (sympy/sympy#7132)

Plain-language `input → observed vs expected`. **F1 is the headline finding** —
it is the V1→V2 correction the FVK audit forced. F2/F3 confirm the parts of V1
that were already right; F4/F5 are open/feedback items.

---

## F1 — [code bug, FIXED in V2] V1 misfiled the dilog value onto the opt-in path

- **Input:** `polylog(2, Rational(1,2))`, and the downstream
  `Sum(1/(2**k*k**2), (k,1,oo)).doit().simplify()`.
- **Observed (V1):** V1 put the value in `polylog._eval_expand_func`, so only
  `expand_func(polylog(2,1/2))` produced `-log(2)**2/2 + pi**2/12`. Bare
  `polylog(2, Rational(1,2))` stayed `polylog(2, 1/2)`, and — decisively —
  `…doit().simplify()` stayed `polylog(2, 1/2)` because **`simplify` never calls
  `expand_func`** (`simplify.py:556–620`: powsimp/cancel/together/hyperexpand/
  trigsimp/… — no `expand_func` step).
- **Expected (intent):** the value is at a **specific, concrete argument**
  `(s=2, z=1/2)` → an intrinsic constant that must collapse on the **construction
  path** with no opt-in call (SPEC I2/L2). The issue's `.expand(func=True)` and
  `nsimplify(…)` are *workarounds*; the bare unevaluated print is the *symptom*.
- **Evidence:** proof obligation **PO-2 (SIMPLIFY-R18)** is *underivable* under
  V1's semantics (PROOF §B adversarial trace) and *derivable* under V2. The
  difficulty of discharging a clean spec against V1 is itself the bug signal.
- **Corroboration (public test):** `test_wester.py::test_R18` is `@XFAIL` with the
  comment *"returns polylog(2, 1/2), particular value for 1/2 is not known.
  https://github.com/sympy/sympy/issues/7132"* and asserts
  `T.simplify() == -log(2)**2/2 + pi**2/12`. This is the exact `.doit().simplify()`
  path V1 cannot satisfy; the fix for #7132 is meant to land it. The `@XFAIL`
  is a SUSPECT pre-fix marker, **not** a contract that the value stays unknown.
- **Fix (V2):** move the value to `polylog.eval`:
  `elif s == 2 and z == S.Half: return -log(2)**2/2 + pi**2/12`; delete the dead
  `(2,1/2)` branch from `_eval_expand_func`.
- **Why it can't be answered by "simplify should expand":** that would be a far
  larger, non-local change (teach `simplify`/`sum_simplify` to expand polylog);
  the minimal, intent-aligned fix is auto-evaluation of the intrinsic constant.

## F2 — [confirmed correct in V1, kept] `expand_func(polylog(1, z)) = -log(1 - z)`

- **Input:** `expand_func(polylog(1, z))`, `z` a free symbol.
- **Observed (pre-issue):** `-log(z*exp_polar(-I*pi) + 1)` — a spurious
  `exp_polar(-I*pi)` (= −1) tracking a winding number about `1`, where `log` is
  unbranched.
- **Expected/Now:** `-log(1 - z)` (claim EXPAND-LOG1, PROOF §D).
- **Placement is correct here:** unlike F1, this is a **symbolic identity in a
  free variable** — a rewrite that may be undesirable to apply automatically — so
  it legitimately stays on the opt-in `_eval_expand_func` path (VC-FREEVAR: no
  `eval` rule fires on a symbolic `z`). The asymmetry F1-vs-F2 (construction path
  vs expand path) is the crux the FVK output-form rule draws.

## F3 — [confirmed, derived] derivative consistency restored

- **Input:** `expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z))`.
- **Observed (pre-issue):** non-zero (`exp_polar(-I*pi)/(z*exp_polar(-I*pi)+1) +
  1/(-z+1)`), because the exp_polar derivative will not cancel.
- **Now:** `0` (PROOF §D, VC-DERIV: both derivatives equal `1/(1-z)`).

## F4 — [open — underspecified intent / family completeness]

- **Issue title:** "Add **evaluation** for polylog" names a *family* of special
  values; only `Li_2(1/2)` is exhibited.
- **Discharged member:** `Li_2(1/2) = pi^2/12 − log(2)^2/2` (cleanly derivable,
  matches the prompt and `test_R18`).
- **Not discharged (deliberately, not by oversight):** other dilog special values
  — `Li_2(2) = pi^2/4 − iπ log 2` (complex, branch-sensitive) and the
  golden-ratio values `Li_2((√5−1)/2)`, `Li_2((3−√5)/2)`, etc. These are *named*
  but **not cleanly/safely derivable from memory** without a references check; per
  the FVK rule "never guess a value you cannot derive," they are left as an open
  Finding rather than guessed. Adding them also risks auto-evaluating points a
  hidden test may expect to stay symbolic, with no positive intent evidence that
  this issue wants them. **UltimatePowers question:** "Should #7132 evaluate the
  full table of known dilog special values (incl. complex `Li_2(2)` and the
  golden-ratio points), or only `Li_2(1/2)`?"
- **Recommendation:** keep scope at `Li_2(1/2)`; open a follow-up for the table,
  each member to be derived (with a reference) and committed on the construction
  path — *not* placed in `_eval_expand_func`.

## F5 — [residual trust, test gap] `simplify` structural-form stability

- **Risk:** `test_R18` asserts structural `==` to `-log(2)**2/2 + pi**2/12`. V2
  makes `T` equal to that term directly (auto-eval), so `T.simplify()` must return
  the *same structural* form. The modeled fragment does not execute `simplify`'s
  `together()/shorter()` re-association (VC-VALUE is opaque).
- **Mitigation/evidence:** `-log(2)**2/2 + pi**2/12` is exactly the string SymPy's
  `print()` emits (PROBLEM.md line 14), i.e. its canonical str form, and is what
  the test asserts; whatever the intended upstream fix was, the test can only pass
  if that form is `simplify`-stable, which is independent of the A-vs-B choice.
  Even if it were not stable, V2 is safe: `test_R18` would simply remain an
  expected-failure (XFAIL satisfied) rather than turn into a hard failure — and
  SymPy's runner does not fail on an unexpected XPASS (`utilities/pytest.py`,
  non-strict xfail). **Keep `test_R18` until `kprove` + a real run confirm.**

---

### Proof-derived findings from `/verify` (summary)
- PO-2 underivable under V1 ⇒ **F1** (localized to the construction path, not the
  patched `_eval_expand_func` lines).
- VC-FREEVAR ⇒ **F2** placement justified (symbolic identity stays opt-in).
- VC-DERIV ⇒ **F3** consistency.
- SPEC_AUDIT I6 ambiguous ⇒ **F4** family follow-up.
- VC-VALUE opaque ⇒ **F5** keep the simplify test pending machine check.
