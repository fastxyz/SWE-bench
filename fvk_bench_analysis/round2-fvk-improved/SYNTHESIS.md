# Round 2 — Synthesis: why the 3 didn't flip, and round-3 materials

## Macro result

Round-1 materials hardening (`third_party/formal-verification-kit` @ `275cd44`) targeted the round-1 STATED mechanism (fvk names the correct fix, then manufactures a no-exec reason to keep the bug). On re-run `fvk-improved-4cases-XC-MINI-PRO-AHP`: **baseline 0/4 → fvk 1/4, +1 flip (`pytest-10356`), 0 regressions.** The hardening worked at its target level — `pytest-10356`, whose whole bug was a fabricated "forcing" proof obligation, flipped once *"a forced claim is a hypothesis to falsify"* was in the materials.

## What happened on the 3 misses

- **sympy-13852 — fvk ACTED, wrong.** The hardening worked: the agent rejected the pre-fix REPL display (round-1's veto) and engaged. It ran the required side-by-side derivation and **correctly labeled the placement choice "under-determined"** — then invented a *secondary* tie-breaker (an unrelated test's "specific value → `expand_func`" pattern + an "expand_func is opt-in" convention) to put the dilog value in `_eval_expand_func` (opt-in) instead of `eval` (construction-time). The graded test asserts the **bare** `polylog(2,2) == …`, so it never evaluates. The agent even foresaw this and bet against it. Class: WRONG-LOCATION (+ PARTIAL coverage, 1-of-6 values).
- **sympy-16597 — fvk CONFIRMED V1.** The hardening half-worked: on Axis A the agent **promoted** the named fix `irrational == real & !rational & finite` to a falsifiable hypothesis (vs. round-1's scope-drop) — then rejected it on a **provably false** constructed ground ("it presupposes the forbidden `real ⟹ finite` change"; it does not — `& finite` merely stops the rule firing for `oo`). Axis B (`algebraic`/`transcendental`) was **never modeled or proposed**, and all 3 FTP tests trip first on Axis B (`oo.is_algebraic is False`). The fix also had to be **mirrored** into a second engine (`ask.py` + generated `ask_generated.py`), untouched. Class: PARTIAL (3-of-4 rules + dual-engine mirror).
- **django-12325 — fvk CONFIRMED V1.** The hardening worked: the agent marked the gold-deleted test SUSPECT, promoted the gold one-liner, ran the side-by-side. It escaped through a **new** hole: it **misread** Django's 1.10 "implicit-promotion deprecated" doc note as "a lone plain OneToOne **must raise**" (conflating *stop auto-promoting* with *reject*), encoded that as a MUST-hold obligation, and used it to **falsify both gold hunks**. Class: PARTIAL (both hunks absent).

## The next-layer rationalizations (round 2's lesson)

The round-1 gates pushed the agent to **engage** (no more silent scope-drop of a named fix); `pytest-10356` flipped. But once engaged, the agent found a **next layer** of no-exec constructed grounds to confirm V1 or under-apply — all still downstream of the **no-execution + hidden-test blind spot** (it cannot see the gold test, so "current behavior" keeps winning):

1. **Obligation laundering** — a *blocking* obligation (the thing that vetoes a promoted fix) is constructed from a **misread doc / error-string** and never audited as genuinely intent-derived. *(django-12325; sympy-16597 Axis A.)*
2. **Tie-break-then-confirm** — a choice correctly labeled *under-determined* is resolved by a **fresh secondary heuristic toward V1**, instead of the issue's explicit desired **output form**. *(sympy-13852.)*
3. **Constructed ground not re-derived against the code's own semantics** — a promoted fix is rejected on a prose claim that is **false** under the actual code semantics. *(sympy-16597 Axis A.)*
4. **Partial application across a homogeneous family + duplicated engines** — the agent fixes **one member** (one rule, one special value) and stops, missing sibling members and **duplicated/generated mirrors**. *(sympy-16597: 1-of-4 rules + un-mirrored `ask_generated.py`; sympy-13852: 1-of-6 values.)*

## Round-3 material changes (general, transferable, no-exec)

Each carries a balance clause (still require positive intent evidence; round-2 kept PASS_TO_PASS 100%, and round-3 must too).

- **R3-A · Blocking obligations need intent provenance.** `commands/verify.md` + `knowledge/intent-evidence.md`: any obligation used to **veto or falsify a promoted/named fix** must itself pass the provenance audit as `intent-derived` — never `implementation-derived` or read off a doc/error string. **Extend the SUSPECT contrapositive to docs, deprecation notes, and error messages**: these are defeasible evidence, not contracts; a note that *deprecates auto-promotion* does not establish that the deprecated input *must raise*. *(django-12325; sympy-16597 Axis A.)*
- **R3-B · No CONFIRM on a tie-break; output-form sets placement.** `commands/verify.md` "Forced choices": once a choice is **under-determined**, you may **not** resolve it with a fresh convention to confirm V1. The issue's explicit **desired output form** is the obligation — a value shown **bare** (no `.expand()`) must hold at **construction time** (the `eval`/constructor path), not only under an opt-in transform. *(sympy-13852.)*
- **R3-C · Fix the whole family; find duplicated/generated engines.** `commands/formalize.md`: when a fix edits **one member of a homogeneous family** (an implication-rule set, a special-value table, an overload group), formalize the **whole family** and `grep` for **duplicated or generated mirrors** (e.g. `*_generated.py`, a second resolver). An untouched sibling or an un-regenerated cache is a Finding. *(sympy-16597 Axis B + mirror; sympy-13852 coverage.)*
- **R3-D · Re-derive a rejection against the code's own semantics.** `commands/verify.md`: a constructed ground that rejects a promoted fix must be **re-derived against the candidate's actual semantics**, not asserted in prose; if the agent cannot demonstrate the breakage concretely, the rejection does not stand. *(sympy-16597 Axis A.)*

## Headroom (honest)

- **sympy-13852 — likely flip.** R3-B removes the tie-break hatch and forces `eval` placement; the graded `test_polylog_values` includes bare `polylog(2,2)` / `polylog(2,1/2)`, which then auto-evaluate. (The four golden-ratio constants aren't text-derivable, but the graded test doesn't require them.)
- **sympy-16597 — partial.** R3-A/R3-D unblock Axis A; R3-C *generates* the Axis-B candidates by family symmetry, but the exact hidden value (`oo.is_algebraic is False`) is unverifiable without execution → raises flip probability, not guaranteed.
- **django-12325 — partial / contingent.** R3-A targets the laundering path, but the residual is partly a **domain misread** (a reasoning-quality limit the issue text — which calls the lone-OTO error "the same bug" — already contradicted, and the agent overrode). Lower confidence.
- **Net:** ~1 likely + 2 contingent additional flips. The ceiling on all three is the **no-exec / hidden-test** blind spot: the materials can stop the agent *manufacturing* reasons to keep V1, but cannot supply the test oracle it lacks.
