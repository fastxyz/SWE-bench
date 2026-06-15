# PUBLIC_EVIDENCE_LEDGER — sympy__sympy-13852

Standalone public-evidence ledger (mirrored in `SPEC.md` and as `SPEC-PROVENANCE`
comments in `polylog-expand-spec.k`). Only public/in-repo evidence is used: the issue
text, the `polylog` docstring, and `test_polylog_expansion`. No hidden tests, gold
patch, evaluator output, or prior-attempt status was consulted.

| # | Source | Quoted public evidence | Obligation | Encoded as |
|---|---|---|---|---|
| L1 | prompt | "The answer should be -log(2)\*\*2/2 + pi\*\*2/12" | `expand_func(polylog(2,1/2))` = that value | claim PL2 |
| L2 | prompt | "polylog(1, z) and -log(1-z) are exactly the same function for all purposes" | `expand_func(polylog(1,z)) = -log(1-z)` | claim PL1 |
| L3 | prompt | "I don't see a reason for exp_polar here" | result free of `exp_polar(-I*pi)` | claim PL1 |
| L4 | prompt | "it would seem that expand_func changes the derivative of the function" | expansion preserves `d/dz` | claim PLDERIV-FIX |
| L5 | prompt | "they have the same derivative, which is z/(1-z)" | `polylog(0,z)=z/(1-z)` ⇒ `d/dz polylog(1,z)=1/(1-z)` | claim PLDERIV-FIX (right) |
| L6 | prompt | "having exp_polar in expressions like -log(1 + 3\*exp_polar(-I\*pi)) is just not meaningful" | no winding factor about `z=1` | claim PL1 (generalized) |
| L7 | docs | docstring `>>> expand_func(polylog(0, z))  z/(-z + 1)` | s≤0 branch preserved | claim PL0 |
| L8 | public-test | `myexpand(polylog(s,…))` pattern; `polylog(-5,z)` still expands | other reductions preserved | claims PLF / frame |
| S1 | prompt (**SUSPECT**) | `Out[1]: polylog(2, 1/2)` (unevaluated) | NOT "stays unevaluated"; symptom only | excluded (SPEC_AUDIT D1) |
| S2 | public-test (**SUSPECT**) | `myexpand(polylog(1, z), -log(1 + exp_polar(-I*pi)*z))` | old buggy output | excluded; must update |

Provenance rule applied: implementation facts (the dispatch branches) are used only to
model *state/transition shape*, never as intent by themselves (entry L8 in SPEC.md).
Every expected value above cites a non-candidate source (prompt, docstring, or the
public-test encoding pattern), satisfying intent-evidence §4.6.
