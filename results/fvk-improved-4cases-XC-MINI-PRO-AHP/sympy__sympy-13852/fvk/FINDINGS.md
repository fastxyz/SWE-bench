# FINDINGS — sympy__sympy-13852

Plain-language `input → observed vs expected`, plus proof-derived findings. The
headline result: **V1 is correct against the full intent**; the audit confirms it,
adds one minimal readability refactor, and records the scope boundaries.

## Formalization findings (`/formalize`)

### F1 — (FIXED in V1) `expand_func(polylog(1, z))` carried a spurious `exp_polar`
- **Input:** `expand_func(polylog(1, z))`.
- **Old observed:** `-log(z*exp_polar(-I*pi) + 1)`.
- **Expected (intent I2/I4):** `-log(1 - z)`.
- **Why it's a bug:** the `exp_polar(-I*pi)` encodes a winding number about `0`, but
  the `+1` makes the relevant branch point `z = 1`, where `log` is unbranched — so
  the information is meaningless, and it breaks differentiation (F3).
- **Status:** fixed by `if s == 1: return -log(1 - z)`. Verified by claim (PL1).

### F2 — (FIXED in V1) `expand_func(polylog(2, 1/2))` did not evaluate
- **Input:** `polylog(2, Rational(1,2)).expand(func=True)`.
- **Old observed:** `polylog(2, 1/2)` (unchanged).
- **Expected (intent I1):** `-log(2)**2/2 + pi**2/12`.
- **Status:** fixed by the new `s == 2 and z == S.Half` branch. Verified by (PL2) and
  the numeric check in PROOF §Numeric (`= 0.58224…`, matches mpmath).

### F3 — (FIXED in V1, load-bearing) expansion changed the derivative
- **Input:** `expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z))`.
- **Old observed:** `exp_polar(-I*pi)/(z*exp_polar(-I*pi) + 1) + 1/(-z + 1)` (≠ 0).
- **Expected (intent I3):** `0`.
- **Status:** the new `-log(1 - z)` has derivative `1/(1-z) = polylog(0,z)/z`, so the
  residual is `0`. This is **PO-6**, the obligation that formally separates the fixed
  code from the buggy code (PROOF §PO-6 shows the old form cannot discharge it).

## Adequacy / design findings

### F4 — Design decision: dilog value in `_eval_expand_func`, not `eval` (under-determined, resolved)
- **The named alternative:** auto-evaluate `polylog(2, 1/2)` in `eval` (would also
  change the issue's `In[1]`). Promoted to a hypothesis (not dropped on scope), and
  derived side-by-side in `SPEC_AUDIT.md` D1.
- **Resolution:** keep it in `_eval_expand_func`. Positive grounds (NOT "preserve the
  unevaluated symptom"): the public test `test_polylog_expansion` tests every
  **specific-`(s,z)`** reduction (`s=1,0,-1,-5`) via `myexpand`/`expand_func` and
  reserves bare `==` for **universal-`z`** reductions (`z∈{0,1,-1}`); `(2,1/2)` is
  specific, so the `expand_func` path matches the established intent encoding. The
  whole `polylog` class routes non-universal closed forms through `_eval_expand_func`.
  Both placements satisfy the explicit `.expand(func=True)` requirement; `eval` adds
  an unrequested auto-transform side effect.
- **Honoring the FVK warning:** we explicitly do **not** assert "polylog(2,1/2) stays
  unevaluated" as an invariant (S1); the choice rests on the test pattern + the named
  `expand_func`-is-opt-in convention, both positive evidence.
- **UltimatePowers question for the maintainer:** "Should `polylog(2, 1/2)` evaluate
  automatically (like `zeta(2)→π²/6`), or only under `expand_func` (like every other
  `polylog` reduction)?" Either is defensible; the codebase convention says
  `expand_func`.

### F5 — Scope boundary: only `z = 1/2` for `s = 2`; the `s<0` loop not re-proved
- The fix adds exactly one special value (the only one the issue names). Other dilog
  special arguments and a general `polylog(2, z)` reduction are **not** added — there
  is no elementary closed form for general `z`. The pre-existing `s<0` rational
  loop is unchanged and not re-verified (PROOF §Loop, PO-LOOP). These are deliberate,
  intent-justified boundaries, not omissions.

## Proof-derived findings (`/verify`)

### F6 — PO-6 is the proof that V2 ≠ V1-bug
- The derivative-consistency VC discharges for `-log(1 - z)` and provably **fails**
  for `-log(1 + exp_polar(-I*pi)*z)` (the opaque `exp_polar` constant never reduces
  to `-1`). So the fix is not cosmetic: it is exactly the edit that makes PO-6 close.
- **Test impact:** the public assertion `myexpand(polylog(1, z), -log(1 + exp_polar(-I*pi)*z))`
  (test_zeta_functions.py:131) encodes the **old buggy output** → SUSPECT (S2). It
  must be updated to `-log(1 - z)` to satisfy the intent. We do not edit tests; the
  graded suite is expected to carry the update. A test that must change to honor the
  intent is a positive bug signal, not a reason to revert the fix.

### F7 — No new precondition or guard is forced by the proof
- Every branch is total; the only domain assumption (`z ≠ 0` in the `polylog(0,z)/z`
  derivative identity) is inherited from SymPy's own `fdiff` and is not a new code
  guard. No "forced" side condition surfaced — consistent with V1 being correct.

## Spec-difficulty signal check

Writing a clean spec for the changed branches was **easy** (each is a one-line
total rule with explicit intent provenance), and the load-bearing derivative property
discharged cleanly. Per the FVK heuristic "spec-difficulty = bug signal", the absence
of difficulty corroborates that V1 is correct — there was no awkward case split, no
invented side condition, and no postcondition that fails on an in-domain input.
