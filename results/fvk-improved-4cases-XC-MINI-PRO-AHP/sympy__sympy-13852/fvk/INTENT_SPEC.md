# INTENT_SPEC — polylog._eval_expand_func (sympy__sympy-13852)

Intent-only English obligations, derived **before** accepting any candidate/legacy
behavior. Sources: `benchmark/PROBLEM.md` (the public issue), the `polylog`
docstring/API contract, and the public test `test_polylog_expansion`. Current code
behavior is recorded only as "observed, to check later", never as expected-by-itself.

## Required behaviors

- **I1 — Dilogarithm value at 1/2.** `polylog(2, 1/2)` must be reducible to the
  closed form `-log(2)**2/2 + pi**2/12`. The issue states *"The answer should be
  -log(2)**2/2 + pi**2/12"* and shows the request mechanism
  `polylog(2, Rational(1,2)).expand(func=True)`.
  - *Source:* prompt (explicit answer + explicit mechanism). Provenance: `intent-derived`.

- **I2 — `polylog(1, z)` is `-log(1 - z)`.** Expanding `polylog(1, z)` must yield
  `-log(1 - z)` and must **not** contain an `exp_polar(-I*pi)` factor. The issue:
  *"polylog(1, z) and -log(1-z) are exactly the same function for all purposes"* and
  *"I don't see a reason for exp_polar here."*
  - *Source:* prompt. Provenance: `intent-derived`.

- **I3 — Derivative consistency.** Expansion must not change the function's
  derivative: `expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z))`
  must be `0`. Equivalently `d/dz polylog(1,z) = polylog(0,z)/z = 1/(1-z)` must equal
  `d/dz(-log(1-z))`. The issue calls the old behavior a bug precisely because the
  derivative was *not* preserved.
  - *Source:* prompt (worked derivation). Provenance: `intent-derived`.

- **I4 — No spurious branch information.** The result of expanding `polylog(1, z)`
  must not carry a winding-number/`exp_polar` factor about the point `z = 1`, where
  `log` is unbranched. *"having exp_polar in expressions like -log(1 + 3*exp_polar(-I*pi))
  is just not meaningful."*
  - *Source:* prompt. Provenance: `intent-derived` (generalization of I2).

- **I5 — Preserve the already-correct reductions (frame condition, narrow).** The
  other documented `expand_func` reductions must keep working:
  `polylog(s, 0)=0`, `polylog(s, 1)=zeta(s)`, `polylog(s, -1)=-dirichlet_eta(s)`
  (automatic), `expand_func(polylog(0, z)) = z/(1 - z)`, `polylog(-1, z)` and
  `polylog(-5, z)` still expand via the `s <= 0` loop.
  - *Source:* docstring + `test_polylog_expansion`. Provenance: `intent-derived`
    (named public behavior). This frame is sliced narrowly: it preserves the
    *named* reductions, not "every byte of the old output" — in particular it does
    **not** preserve the old `exp_polar` form of `polylog(1, z)` (which I2 changes).

## Explicitly NOT obligations (SUSPECT legacy / symptom displays)

- **S1 — "`polylog(2, 1/2)` prints unevaluated."** The issue's `In[1]`/`In[2]`
  display `polylog(2, 1/2)` unevaluated. Per FVK intent-evidence §1 + the worked
  note for this exact issue, that display is the **symptom being reported**, not a
  required invariant. We must NOT add an obligation "stays unevaluated by default",
  and must NOT use it to justify a no-op. (See SPEC_AUDIT design decision D1.)

- **S2 — Old `test_polylog_expansion` line.** The pre-fix assertion
  `myexpand(polylog(1, z), -log(1 + exp_polar(-I*pi)*z))` encodes exactly the
  behavior the issue calls buggy ⇒ SUSPECT. The fix legitimately requires this test
  to be updated to `-log(1 - z)`; a test we must change to satisfy the intent is a
  positive bug signal, not a reason to keep V1's value identical to the old code.

## Default-domain assumptions (named)

- **D-dom1 — Principal branch.** `log` and `polylog` use SymPy's principal branch.
  On `z` real `> 1`, both `polylog(1, z)` and `-log(1-z)` take imaginary part `-pi`
  (the issue confirms this numerically against mpmath). So I2's identity holds on
  the cut, not just for `|z| < 1`.
- **D-dom2 — `expand_func` is opt-in expansion.** SymPy convention: closed-form
  reductions that introduce new function heads (`log`, `pi`) at non-universal
  arguments live in `_eval_expand_func`, reached via `expand(func=True)`; automatic
  `eval` is reserved for universal reductions (here `z ∈ {0, 1, -1}` for all `s`).
  This convention is what places I1 in `_eval_expand_func` rather than `eval`
  (see SPEC_AUDIT D1) — and it is a *named* convention, not an enshrinement of S1.

## Out of scope (recorded, not required)

- General `polylog(2, z)` for symbolic `z` (no elementary closed form).
- Other special dilogarithm arguments (e.g. `2`, golden-ratio values). The issue
  names only `1/2`.
