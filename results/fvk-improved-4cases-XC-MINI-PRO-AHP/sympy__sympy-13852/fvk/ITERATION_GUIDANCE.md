# ITERATION_GUIDANCE — sympy__sympy-13852

Next-iteration guidance distilled from the FVK pass. Bottom line: **V2 stands** (V1
plus one minimal readability refactor). No correctness change was justified by the
artifacts; every obligation in `PROOF_OBLIGATIONS.md` discharges.

## Decision: keep V1's behavior, apply one minimal refactor

- **Behavior unchanged from V1.** `expand_func(polylog(1, z)) = -log(1 - z)` and
  `expand_func(polylog(2, 1/2)) = -log(2)**2/2 + pi**2/12`, with all other reductions
  preserved. Justified by claims PL0–PL2, PLF, PLDERIV-FIX (all pass) and the adequacy
  gate (SPEC_AUDIT: PASS).
- **One refactor applied** (`repo/.../zeta_functions.py`): flattened the nested
  `if z == S.Half: / if s == 2:` into a single guard
  `if s == 2 and z == S.Half:`. Behavior-identical (PO-7 totality unchanged); it makes
  the special-case read in the same flat style as the `s == 1` and `s <= 0` guards.
  Traceable to a low-severity readability finding, not a correctness finding.

## Why no further code change

| Candidate change considered | Source | Disposition |
|---|---|---|
| Auto-evaluate `polylog(2,1/2)` in `eval` | FVK hint + consistency w/ `polylog(2,±1)` | **Rejected on positive grounds** (F4 / SPEC_AUDIT D1): public-test pattern + `expand_func`-is-opt-in convention. Not rejected on scope. |
| Add more dilog special values / general `polylog(2,z)` | "Add evaluation for polylog" title | **Rejected:** issue names only `1/2`; no elementary closed form for general `z` (F5). |
| Re-implement / guard the `s<0` loop | totality | **Rejected:** untouched by the fix, pre-existing and correct (PO-LOOP). |
| Keep `exp_polar` for branch safety | old code | **Rejected:** numerically identical on the cut, breaks PO-6; issue verified equivalence at thousands of points (D-dom1). |

None of these is a "named change dropped on scope grounds": each was promoted to a
hypothesis and rejected against the **full intent** (issue + docstring + public-test
pattern), per FVK verify §3.

## Test-redundancy recommendation (benefit 1) — conditioned on machine-checking

Proof is **constructed, not machine-checked**; treat all removals as *recommendations
pending* `kprove` returning `#Top`. Until then, **keep every test.**

| Test (test_zeta_functions.py) | Verdict | Reason |
|---|---|---|
| `myexpand(polylog(1, z), …)` | **MUST UPDATE** (not remove) | Currently asserts the buggy `exp_polar` form (SUSPECT S2); update target to `-log(1 - z)` per claim PL1. Do not edit here — graded/hidden suite owns it. |
| New `polylog(2, 1/2)` expansion assertion (expected in graded suite) | **KEEP** | Directly checks PL2; the headline behavior. |
| `myexpand(polylog(0, z), z/(1 - z))`, `polylog(-1,z)`, `polylog(-5,z)` | **KEEP** | Exercise the untouched `s<=0` loop — outside the re-proved core (PO-LOOP). |
| `polylog(s,0)`, `polylog(s,1)`, `polylog(s,-1)` | **KEEP** | Universal `eval` reductions; outside `_eval_expand_func`'s changed branches. |
| `test_derivatives` `td(polylog(b, z), z)` | **KEEP** | Termination/numeric-derivative check; partial-correctness proof says nothing about it. |

Net: **no test is recommended for removal.** The change is a bug fix that *tightens*
behavior; its proof subsumes no existing in-domain unit point that would be safe to
delete (the closest, the `polylog(1,z)` assertion, must instead be corrected).

## If a future pass wants to extend this

1. Run the `kompile`/`kprove` commands in `polylog-expand-spec.k` to upgrade the proof
   to machine-checked, then revisit test-redundancy.
2. If maintainers prefer auto-evaluation (F4), move the dilog value to `eval` and add
   a fast `_eval_evalf` consistency test; the `_eval_expand_func` branch can stay as a
   defensive duplicate for `evaluate=False`-constructed objects.
3. To generalize beyond `1/2`, implement the dilogarithm reflection/Landen identities
   behind `expand_func` (with provenance), not in `eval`.
