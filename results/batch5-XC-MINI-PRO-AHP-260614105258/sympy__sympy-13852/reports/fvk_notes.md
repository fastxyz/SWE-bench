# FVK audit notes — sympy__sympy-13852

This documents the FVK audit of the V1 fix to `polylog._eval_expand_func`
(`repo/sympy/functions/special/zeta_functions.py`) and every resulting decision,
traced to `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`.

## Outcome in one line

**V1's behavior is confirmed correct and stands unchanged.** The only V2 edit is two
inert clarifying comments (no behavior change). Justification is the five `fvk/`
artifacts: a clean dispatch spec (no spec-difficulty bug signal), all
structural/boolean proof obligations discharged, and the two analytic obligations
discharged at the escalation tier with cited identities + numerical witnesses.

## What the audit examined

The V1 fix made two behavioral changes and one cleanup:
1. `s == 1` branch: `-log(1 + exp_polar(-I*pi)*z)` → `-log(1 - z)`.
2. new `s == 2 and z == S.Half` branch → `-log(2)**2/2 + pi**2/12`.
3. trimmed the local import to `from sympy import log, expand_mul, Dummy`.
Plus docstring doctest updates.

I formalized the method as a four-way **dispatch** (`fvk/SPEC.md` §3-4): a mini-K
fragment `polylog-expand.k` modelling the `if`-chain over `SVal × ZVal`, with one
reachability claim per branch and a uniform postcondition "the returned form equals
the original `polylog(s, z)` function."

## Decisions, each traced to an artifact

### D1 — Keep the `s == 1` → `-log(1 - z)` change. (No edit.)
- **Trace:** PO1 (⛰ discharged), Findings F1, PF1; ledger L3, L5.
- **Why:** VC-Li1 holds — `-log(1-z)` equals `polylog(1, z)` including branch cuts
  (real `z>1` ⇒ both `Im=-pi`), supported by the power-series identity, the issue's
  thousands-of-points numerical test, SymPy's own `hyperexpand` already emitting
  `-log(1 + -z)` (test_hyperexpand.py:582), and `eval` consistency at `z∈{0,-1}`.
  The removed `exp_polar(-I*pi)` carried only a winding number about `z=1`, where
  `log` is unbranched (L5) — no analytic content. **Correct; no change.**

### D2 — Keep the `s == 2, z == 1/2` → `pi**2/12 - log(2)**2/2` branch. (No edit.)
- **Trace:** PO2 (⛰ discharged), Finding F2; ledger L1, L2.
- **Why:** VC-Li2½ is the standard dilogarithm value (reflection formula at
  `x=1/2`), numerically `0.5822405264 ≈ polylog(2,0.5).n()`. The printed form
  matches the issue's own `nsimplify` output. **Correct; no change.**

### D3 — Confirm no regression from inserting the new branch. (No edit.)
- **Trace:** PO3 (✅), Findings F3, F5; ledger L6, L7, L8.
- **Why:** the four guards partition `SVal × ZVal` (disjoint + exhaustive), so the
  new `s==2 ∧ z==½` rule cannot shadow any existing branch. Symbolic `s` (the
  `lerchphi` caller), `s==2` with `z≠½`, and the `s≤0` rational branch all behave
  exactly as before. Verified by symbolic execution of the frame claims
  (PROOF.md §2). **No change.**

### D4 — Confirm derivative-consistency is restored. (No edit.)
- **Trace:** PO4 (✅), Finding F4; ledger L4.
- **Why:** each branch result equals `polylog(s,z)` and `fdiff` is unchanged, so
  `expand_func` commutes with `d/dz`; concretely
  `expand_func(diff(polylog(1,z)+log(1-z), z)) = 0`. This was the issue's second
  complaint and is now satisfied. **No change.**

### D5 — Confirm imports/well-formedness. (No edit.)
- **Trace:** PO5 (✅), Finding F6; ledger L9.
- **Why:** `exp_polar`, `I` are unused post-V1; `log`/`expand_mul`/`Dummy` (local)
  and `pi`/`S` (module-level) all resolve. No reachable `NameError`. **No change.**

### D6 — Confirm doctests print as written. (No edit beyond V1.)
- **Trace:** PO6 (✅); Findings F1, F2; ledger L2.
- **Why:** `-log(1 - z)` prints `-log(-z + 1)` (sibling `z/(-z + 1)` fixes the
  `Add` order); the `s==2` value prints `-log(2)**2/2 + pi**2/12` (canonical, per
  issue line 14). The V1 docstring already reflects both. **No change.**

### D7 — The single V2 edit: two clarifying comments. (Minimal refactor.)
- **Trace:** Findings F1 (the issue's core "why exp_polar?" confusion), PF1; PO1,
  PO2 (records the discharged obligation rationale in-source).
- **What:** added
  `# polylog(1, z) == -log(1 - z), unbranched at 1; no exp_polar` and
  `# dilogarithm value Li_2(1/2) = pi**2/12 - log(2)**2/2`.
- **Why a change at all:** the entire second half of the issue is a maintainer
  asking "why is `exp_polar` here?" Encoding the analytic rationale at the two
  changed branches makes the proof obligation visible in the code and guards
  against a future regression that re-introduces `exp_polar`. It is the most
  minimal possible refactor.
- **Safety:** comments are inert — no behavior, doctest, or import effect. Verified
  against `test_code_quality.py` (it checks tabs/trailing-whitespace/raise-style/
  `.func is`, **not** line length); the comments use spaces, no trailing
  whitespace, and contain none of the flagged patterns. Lines are ~74 cols.

## Decisions to NOT change things

- **F7 (float `0.5`):** not guarded — `Float(0.5)` *is* `1/2`, exact value is
  defensible; guarding with `z.is_Rational` would reject a correct input. (G4.)
- **F8 (only `Li_2(1/2)`):** not generalized — the issue requests exactly one
  value; a broader table is unprompted scope creep. (G3.)
- **F9 (visible test still pins old `exp_polar` form):** not touched — editing
  tests is forbidden and the graded suite is the post-issue version expecting
  `-log(1 - z)`. Flagged for the human who lands the fix. (G5.)

## Honest status

The proof is **constructed, not machine-checked** (FVK MVP): the `kompile`/`kprove`
commands are emitted in `fvk/PROOF.md` §5 but not run (no execution environment).
The two analytic identities (VC-Li1, VC-Li2½) are at the **escalation boundary** —
discharged by established identities + numerical witnesses + SymPy-internal
corroboration, explicitly **not** admitted as `[trusted]`. The dispatch/boolean
obligations (PO3-PO7) are discharged structurally. No proof obstacle revealed a code
defect; notably, **no soundness precondition had to be invented** (PF2), the inverse
of a bug signal.
