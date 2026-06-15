# ITERATION_GUIDANCE.md — polylog fix

What the next code/spec/test pass should do, traced to FINDINGS and
PROOF_OBLIGATIONS. The headline outcome of this FVK pass: **V1 was revised**, not
confirmed — the dilog value was moved from the opt-in `expand_func` path to the
construction path (`eval`).

---

## 1. Code changes made this pass (and why)

| Change in `repo/sympy/functions/special/zeta_functions.py` | Justified by |
|---|---|
| `polylog.eval`: add `elif s == 2 and z == S.Half: return -log(2)**2/2 + pi**2/12` | F1 / PO-1 / PO-2 — intrinsic specific-point constant belongs on the construction path; required for `test_R18`'s `.doit().simplify()` |
| `polylog._eval_expand_func`: **remove** the dead `if z == S(1)/2: if s == 2: …` branch | F1 — once `eval` evaluates it, the value can never reach `_eval_expand_func`; leaving it is dead code |
| `polylog._eval_expand_func`: keep `s == 1` → `-log(1 - z)` | F2 / PO-4 — correct *and* correctly placed (symbolic identity stays opt-in) |
| docstring: add a `polylog(2, Rational(1,2))` auto-eval example; keep `expand_func(polylog(1, z)) → -log(-z + 1)` | F2/F1 documentation; str form verified vs PROBLEM.md line 14 |

These supersede the V1 placement recorded in `reports/baseline_notes.md`
(which filed the value under `_eval_expand_func`).

## 2. Confirm by machine check (gates test removal)

```sh
kompile fvk/mini-sympy.k --backend haskell
kprove  fvk/polylog-spec.k          # expect #Top for EVAL-DILOG, SIMPLIFY-R18,
                                     #        EXPAND-DILOG, EXPAND-LOG1
```
Until `#Top` is returned, treat the proof as *constructed only* and **keep all
tests**.

## 3. Test-redundancy (benefit 1) — recommendation only, do NOT delete

After `kprove` returns `#Top`:

- **Subsumed (in-domain point checks):** an assertion of the single point
  `expand_func(polylog(2,1/2)) == -log(2)**2/2 + pi**2/12` (or the bare
  `polylog(2,1/2) == …`) is entailed by **EVAL-DILOG**. `polylog(2,1/2)` via
  `…doit().simplify()` is entailed by **SIMPLIFY-R18**.
- **KEEP (out of the verified fragment):**
  - `test_R18` itself until the `together()/shorter()` form-stability (F5) is
    machine-confirmed;
  - all symbolic / free-variable polylog tests (`polylog(s,z)` derivative,
    rewrite, `expand_func(polylog(1,z))`, `polylog(0,z)`, `polylog(-1,z)` …) —
    they exercise paths the dilog claim does not cover;
  - `test_args.py` construction test (different inputs).
- **Never auto-delete; this is advisory** (Honesty gate).

## 4. Open items for the next pass

- **F4 — dilog family.** Decide scope (UltimatePowers question in FINDINGS F4). If
  the full table is wanted, add each member to `polylog.eval` (construction path),
  each derived with a cited reference; do **not** route any member through
  `_eval_expand_func`. Until then, scope stays `Li_2(1/2)`.
- **F5 — simplify form stability.** Add/keep a check that
  `simplify(-log(2)**2/2 + pi**2/12)` is structurally stable, or assert via
  `.equals(...)` rather than `==`, to harden `test_R18` against re-association.

## 5. Adversarial self-check performed

- **Localized from the symptom, not the diff.** Did not assume the bug lived in
  the lines V1 changed (`_eval_expand_func`). Traced `test_R18`'s symptom
  backward: `.doit() → polylog(2,1/2)`; `.simplify()` has no `expand_func` step ⇒
  the value must be produced earlier, on construction. PROOF §B reproduces the
  failure symbolically on V1 and shows V2 removes it.
- **"Forced"-choice falsification.** Candidate placements named and compared
  side-by-side: (A) `_eval_expand_func` only [V1] vs (B) `eval` [V2]. Predicted
  outputs: A leaves `…doit().simplify()` = `polylog(2,1/2)` (fails I5); B yields
  the closed form on every path (bare, `.expand`, `.simplify`, `.doit`). B
  dominates: it satisfies a superset of A's obligations with no public obligation
  lost. The placement is therefore **not** under-determined — resolved toward the
  construction path by the bare-form rule, never toward V1 by a "siblings live in
  expand_func" convention (the `s==1` sibling is a symbolic identity, which does
  not pull a specific-point constant off the construction path).
- **No `V2 == V1` rationalization used.** The audit named a concrete change
  (move to `eval`) and applied it; it was not dropped on "out of scope" grounds.
