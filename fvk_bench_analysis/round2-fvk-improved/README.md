# FVK Bench — Round 2: improved-materials run, the 3 remaining misses

Round 1 hardened the FVK materials (submodule `275cd44`) against the round-1 **STATED** mechanism — fvk localizes the correct fix, names it, then manufactures a no-exec reason to keep the bug. Re-run **`fvk-improved-4cases-XC-MINI-PRO-AHP`** (`--arms baseline,fvk`, max-parallel 4):

- **baseline 0/4 → fvk 1/4; +1 flip (`pytest-dev__pytest-10356`), 0 regressions** (PASS_TO_PASS held 100% on every arm).
- The flip is the "fabricated forcing proof obligation" case (the whole bug was the `reversed(__mro__)` token) — realized once *"a forced claim is a hypothesis to falsify"* entered the materials.

This round post-mortems the **3 that did not flip**, with a *forward* question (not round-1's "is the root cause present?"): the materials made the agent **engage** — **why is its action wrong, and what further general/no-exec material change closes the gap to gold?**

## Per-instance (round 2)

*fvk acted?* = did `solution_fvk.patch` differ from V1. *Class* = WRONG-LOCATION / PARTIAL / WRONG-VALUE / OVER-REACH. *Closable* = by a round-3 material change.

| instance | fvk acted? | failure class | FAIL_TO_PASS still failing | closable by materials? | analysis |
|---|---|---|---|---|---|
| sympy__sympy-13852 | **yes (edited)** | WRONG-LOCATION + PARTIAL | `test_polylog_values` | **likely** | [link](sympy__sympy-13852/ANALYSIS.md) |
| sympy__sympy-16597 | no (confirmed V1) | PARTIAL (3-of-4 rules + dual-engine mirror) | `test_infinity`, `test_neg_infinity`, `test_other_symbol` | partial | [link](sympy__sympy-16597/ANALYSIS.md) |
| django__django-12325 | no (confirmed V1) | PARTIAL (both gold hunks) | `test_clash_parent_link`, `test_onetoone_with_parent_model` | partial | [link](django__django-12325/ANALYSIS.md) |

**Key correction vs. the at-a-glance run output:** non-empty `solution_fvk.patch` line counts do **not** mean fvk edited — for django-12325 and sympy-16597 the fvk patch is **byte-identical to baseline** (fvk still *confirmed V1*); only sympy-13852 (and the flipped pytest-10356) actually changed the code.

See [SYNTHESIS.md](SYNTHESIS.md) for the cross-cutting "next-layer rationalizations" and the prioritized round-3 material changes.
