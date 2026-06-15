# PROOF_OBLIGATIONS.md — polylog fix

Obligations the proof must discharge, traced to the intent ledger in
[`SPEC.md`](SPEC.md). Each is a reachability claim over
[`mini-sympy.k`](mini-sympy.k); the discharges are in [`PROOF.md`](PROOF.md).
There is **no loop / recursion** in the unit, so there is **no circularity /
invariant obligation** — only function-style reachability rules and the
arithmetic/identity VCs they generate. (Default scope: partial correctness;
termination of the rewrite system is trivial — every rule strictly shrinks the
term toward a normal form, noted but not the focus.)

| ID | Obligation (reachability) | Ledger | Discharged by | Risk if missed |
|----|---------------------------|--------|---------------|----------------|
| **PO-1** EVAL-DILOG | `polylog(2, half) ⇒ pi^2/12 − log(2)^2/2` on the bare term (no wrapper) | L1, L2 | rule `eval-dilog`; PROOF §A | the *primary* issue request unmet |
| **PO-2** SIMPLIFY-R18 | `simplify(Li2sum_half) ⇒ pi^2/12 − log(2)^2/2` | L5, L7 | PROOF §B (needs PO-1) | `test_R18` fails — the decisive discriminator vs V1 |
| **PO-3** EXPAND-DILOG | `expand(polylog(2, half)) ⇒ pi^2/12 − log(2)^2/2` | (no-regress L2) | PROOF §C (needs PO-1 + `expand-id`) | issue's `.expand(func=True)` workaround regresses |
| **PO-4** EXPAND-LOG1 | `expand(polylog(1, Z)) ⇒ neg(log(1 − Z))`, free `Z` | L3 | rule `expand-log1`; PROOF §D | exp_polar bug unfixed |
| **PO-5** DERIV-CONSISTENT | `d/dz[polylog(1,z)] = d/dz[−log(1−z)]` after PO-4 | L4 | PROOF §D (arith VC) | derivative still inconsistent |
| **PO-6** NO-BREAKAGE | the construction rule fires only at `(s,z)=(2,1/2)`; every other in-domain `(s,z)` keeps its V1 normal form | compat audit | PROOF §E | regress an existing PASS test |

## Verification conditions (arithmetic / side conditions)

- **VC-PLACEMENT (the operative one).** Under the V1 semantics (rule
  `eval-dilog` **absent**, an `expand(polylog(2,half)) ⇒ DILOG` rule **present**),
  symbolic execution of PO-2 gets *stuck* at `simplify(polylog(2, half))`, whose
  only matching rule is `simplify-noexpand`, giving normal form
  `polylog(2, half) ≠ DILOG`. So **PO-2 is underivable under V1** — this is not a
  missing-precondition VC, it is a *localization* result: the bug lives on the
  construction path, not in `expand_func`. Discharged for V2 because `eval-dilog`
  reduces the inner term before `simplify` is reached. (PROOF §B, adversarial.)
- **VC-FREEVAR.** EXPAND-LOG1 requires that no `eval` rule fires on
  `polylog(1, Z)` with symbolic `Z`: indeed `Z ∉ {0, 1, neg(1)}` and `1 ≠ 2`, so
  the only applicable rule is `expand-log1`. Confirms the `s==1` rewrite is
  legitimately opt-in (a free-variable identity), not a construction-path value.
- **VC-DERIV.** `d/dz[−log(1−z)] = 1/(1−z)` and
  `d/dz[polylog(1,z)] = polylog(0,z)/z`, with `expand_func(polylog(0,z)) =
  z/(1−z)` ⇒ `polylog(0,z)/z = 1/(1−z)`. Both equal `1/(1−z)`; difference `= 0`.
  Linear, Z3-dischargeable. (PROOF §D.)
- **VC-VALUE.** `pi^2/12 − log(2)^2/2` is treated as an opaque normal form; the
  claims check *syntactic reachability* to exactly that term (the canonical str
  form, confirmed against PROBLEM.md line 14). No arithmetic re-association is
  performed, so `shorter()`/`together()` reordering inside `simplify` is out of
  the modeled fragment — flagged as residual trust in PROOF §F.

## Adequacy gate (must pass before trusting any discharge)

1. `SPEC.md` contains INTENT_SPEC (§1), ledger (§2), FORMAL_SPEC_ENGLISH (§3),
   SPEC_AUDIT (§4), PUBLIC_COMPATIBILITY_AUDIT (§5). ✅ present & non-empty.
2. Read FORMAL_SPEC_ENGLISH as the only spec: it states the value, its
   construction-path placement, the no-exp_polar identity, and the downstream
   simplify reachability — no weaker, no stronger. ✅
3. SPEC_AUDIT marks one item **partial/ambiguous** (I6 family) → routed to Finding
   F4, *not* used to bless `V2==V1`. No compatibility callsite unhandled. ✅
