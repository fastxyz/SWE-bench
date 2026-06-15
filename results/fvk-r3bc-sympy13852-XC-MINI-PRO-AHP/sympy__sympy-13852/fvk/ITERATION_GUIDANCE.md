# ITERATION_GUIDANCE.md — `polylog` (sympy 13852)

Proof-derived guidance for the next code/spec/intent iteration. Derived only
from public intent + the FVK artifacts (no hidden-test or evaluator signal).

---

## 1. What V2 changed vs V1 (and why)

| Aspect | V1 | V2 | Driver |
|--------|----|----|--------|
| `polylog(2, 1/2)` placement | in `_eval_expand_func` (opt-in) | in `eval` (construction) | **F1 / PO-1 / PO-2** — bare-form placement rule; "do not enshrine stays-unevaluated" |
| `expand_func(polylog(1,z))` | `-log(1 - z)` | `-log(1 - z)` (unchanged) | F2 / PO-5 — confirmed correct in V1 |
| dead `(2,1/2)` case in `_eval_expand_func` | present | removed | superseded by the `eval` rule (unreachable after the move) |

Net code delta from V1: two edits in `zeta_functions.py` — add the `(2,1/2)`
branch to `polylog.eval`; delete the `(2,1/2)` branch from
`polylog._eval_expand_func`. The `s==1 → -log(1-z)` fix and the import/docstring
cleanups from V1 stand.

## 2. UltimatePowers-style questions for the intent layer

1. **Family scope (F3):** "Should `polylog(2, z)` auto-evaluate the *whole*
   standard dilogarithm table (`Li_2(2)`, the golden-ratio values), or only
   `Li_2(1/2)` as the issue requests?" — governs whether F3 is in or out of
   scope.
2. **Higher orders:** "Should `polylog(3, 1/2) = 7*zeta(3)/8 - pi**2*log(2)/12 +
   log(2)**3/6` (and similar `s>2` values) also evaluate?" — currently no.
3. **Float inputs:** "Is auto-evaluating `polylog(2, 0.5)` to the *exact*
   symbolic closed form desired, or should a Float `z` stay numeric?" (V2 follows
   the pre-existing `polylog(s, 1.0) → zeta(s)` precedent and evaluates.)

## 3. Recommended next code/spec changes

- **If F3 is in scope:** add the remaining `Li_2` table to `polylog.eval`, each
  guarded by an mpmath numeric cross-check test, and extend the docstring with a
  (machine-checked) example for `polylog(2, S.Half)`.
- **Docstring example (deferred, not added now):** a doctest
  `>>> polylog(2, S.Half)` would document F1, but its printed Add ordering
  (`-log(2)**2/2 + pi**2/12` vs `pi**2/12 - log(2)**2/2`) cannot be confirmed
  without execution; adding an unverified doctest risks a CI failure, so it is
  intentionally omitted (honesty gate). Add it once runnable.
- **No further change required for the reported issue:** PO-1..PO-7 all
  discharge; the two reported symptoms (bare `polylog(2,1/2)` unevaluated; the
  `exp_polar`) are removed.

## 4. Test guidance (recommendation only — never auto-deleted)

- **Keep:** `myexpand(polylog(-1,z),…)`, `myexpand(polylog(-5,z),None)` (loop at
  concrete depths — PO-8 is termination/count only); `td(polylog(b,z),z)`
  (numeric); any added F3 inputs (kept until their values are machine-checked).
- **Update expected value (SUSPECT, F4):** the `polylog(1, z)` expansion test
  target must become `-log(1 - z)`; the old `-log(1 + exp_polar(-I*pi)*z)`
  encodes the bug. (We do not edit tests; the hidden/updated suite is expected to
  carry the corrected target.)
- **Redundant once machine-checked:** the `polylog(s,0/1/-1)` evals and
  `polylog(0,z)` expansion (entailed by PO-3 / EXPAND-S0). Conditioned on
  `kprove` returning `#Top` (see PROOF.md §G); until then, keep them.

## 5. Residual risk

- Proof is **constructed, not machine-checked** (no execution env).
- **Partial-correctness** elsewhere; the one loop (PO-8) is additionally
  terminating (decreasing counter `N`).
- Trusted base: the mini-sympy fragment's adequacy as a model of construction +
  dispatch; K reachability metatheory; Z3 for the single linear VC.
- **Completeness gap:** I8/F3 (dilogarithm family) is un-audited beyond `1/2` —
  named, not silently dropped. A green proof of PO-1..PO-8 is necessary but not
  sufficient for "the whole intent is done"; F3 is the explicit residue.
