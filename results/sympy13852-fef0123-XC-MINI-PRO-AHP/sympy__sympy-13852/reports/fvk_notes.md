# FVK notes — audit and revision of the V1 polylog fix

This pass applied the Formal Verification Kit methodology to the V1 fix recorded
in `reports/baseline_notes.md`. **Outcome: V1 was revised, not confirmed.** The
audit found that V1 placed the dilogarithm value on the wrong evaluation path.
The FVK artifacts are in `fvk/` (`SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`,
`PROOF.md`, `ITERATION_GUIDANCE.md`, plus the formal core `mini-sympy.k` and
`polylog-spec.k`). Every decision below traces to those artifacts.

---

## The headline correction (V1 → V2)

**V1 did:** in `polylog._eval_expand_func`, `if z == S(1)/2: if s == 2: return
-log(2)**2/2 + pi**2/12` — i.e. the value was produced only by
`expand_func(polylog(2, 1/2))`.

**V2 does:** in `polylog.eval`, `elif s == 2 and z == S.Half: return
-log(2)**2/2 + pi**2/12` — the value is produced on the **construction path**;
the now-dead branch was removed from `_eval_expand_func`.

**Why (FINDINGS F1 / PROOF_OBLIGATIONS PO-1, PO-2):** the value sits at a
*specific, concrete argument* `(s=2, z=1/2)`. The FVK output-form rule
(intent-evidence.md §3, corollaries (a)/(b)) classifies that as an **intrinsic
constant** that must collapse on the default/construction path with **no opt-in
call**. The issue's `.expand(func=True)` and `nsimplify(expand_func(...).evalf())`
are the user's *workarounds*; the bare `Out[1] = polylog(2, 1/2)` is the
*symptom*, which the SUSPECT rule says must not be enshrined as "stays
unevaluated by default." Filing the constant next to the `s==1` symbolic rewrite
inside `_eval_expand_func` is exactly the "misfile" the methodology warns about.

This was not accepted on methodology alone — it was forced by a **proof
obligation that V1 cannot discharge**. PO-2 (SIMPLIFY-R18) models the public test
`test_wester.py::test_R18`, which is `@XFAIL`, cites issue #7132 in its comment,
and asserts `Sum(1/(2**k*k**2),(k,1,oo)).doit().simplify() == -log(2)**2/2 +
pi**2/12`. I verified in source that **`simplify` never calls `expand_func`**
(`repo/sympy/simplify/simplify.py:556–620`; the one `expand_func` at line 296 is
inside an unrelated hypergeometric-summation helper). Therefore under V1's
expand-only placement, `…doit().simplify()` reduces to `polylog(2, 1/2)`, not the
closed form — PROOF §B reproduces this stuck trace symbolically on the V1
semantics and shows V2's single `eval` line removes it. V2 makes `doit()` itself
yield the closed form (the constructed `polylog(2, Rational(1,2))` auto-evaluates),
so the `.simplify()` is a trivial identity.

I also ran the FVK "forced-choice" falsification (ITERATION_GUIDANCE §5):
placement A (`_eval_expand_func`, V1) vs B (`eval`, V2), side by side. B yields
the value on *every* path (bare, `.expand`, `.simplify`, `.doit`) and loses no
obligation A satisfied; A fails I5/PO-2. The choice is not under-determined — it
resolves to the construction path on the bare-form rule, never back to V1 via a
"siblings live in expand_func" convention.

## What was kept from V1 (confirmed correct, with justification)

- **`expand_func(polylog(1, z)) = -log(1 - z)` stays in `_eval_expand_func`**
  (FINDINGS F2 / PO-4, PO-5). Unlike the dilog constant, this is a **symbolic
  identity in a free variable** — a rewrite that may be undesirable to apply
  automatically — so the opt-in `expand_func` path is the *correct* placement
  (VC-FREEVAR: no `eval` rule fires on a symbolic `z`). The F1-vs-F2 asymmetry
  (construction path for the specific-point constant, expand path for the
  free-variable identity) is precisely the distinction the methodology draws.
  PROOF §D shows the result carries no `exp_polar`, and the derivative-consistency
  obligation PO-5 discharges to `0`.
- **Removal of the unused `exp_polar, I` local import** and the docstring update
  `expand_func(polylog(1, z)) → -log(-z + 1)` — unchanged from V1, still correct.

## Other deliberate decisions

- **Did not broaden the dilog family (FINDINGS F4).** The title "Add evaluation
  for polylog" names a family, but only `Li_2(1/2)` is exhibited and cleanly
  derivable. `Li_2(2)` (complex, branch-sensitive) and the golden-ratio values
  are *named but not safely derivable from memory*; per "never guess a value you
  cannot derive," they are an open Finding with an UltimatePowers question, not a
  guess. Implementing them would also auto-evaluate points a hidden test may
  expect symbolic, with no positive intent evidence this issue wants them. Scope
  stays `Li_2(1/2)`; the follow-up must place any new member on the construction
  path too.
- **Did not modify `simplify`/`sum_simplify` (FINDINGS F1).** Teaching `simplify`
  to expand polylog would be a non-local change; auto-evaluating the intrinsic
  constant in `polylog.eval` is the minimal fix that satisfies the same test.
- **Added a `polylog(2, Rational(1,2))` docstring example.** The printed form
  `-log(2)**2/2 + pi**2/12` is the canonical str output (it is the `print(...)`
  result quoted in PROBLEM.md line 14), so the doctest is safe.

## No-breakage check (PROOF §E / SPEC §5 compatibility audit)

`eval`'s new branch matches only `(s,z) = (2, 1/2)`; every other in-domain pair
keeps its V1 normal form. No public callsite or in-repo test constructs that
specific pair expecting a `polylog` instance — `test_args.py` uses
`polylog(x, y)` (symbols); `test_hyperexpand.py` uses `polylog(2, z)` (symbol
`z`); `lerchphi._eval_expand_func` calls `polylog(s, …)._eval_expand_func` only
with symbolic `s`. The only residual-trust item is `test_R18`'s structural
`simplify` form (FINDINGS F5), which is argued safe either way (if the form were
unstable, `test_R18` would remain an expected-failure, and SymPy's runner does
not fail on an XPASS — `utilities/pytest.py`, non-strict xfail) and is flagged to
keep until machine-checked.

## Honesty

The proof is **constructed, not machine-checked**; the `kompile`/`kprove`
commands are emitted in `fvk/PROOF.md` / `fvk/polylog-spec.k`. Test-removal
recommendations (ITERATION_GUIDANCE §3) are advisory and conditioned on a `#Top`
from `kprove`; nothing was deleted.
