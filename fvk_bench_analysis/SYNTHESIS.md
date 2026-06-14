# SYNTHESIS — FVK improvement headroom on batch1–5 failures

*Cross-instance synthesis of all 11 fvk-failing instances in batch1–5. Per-instance detail in each `<instance_id>/ANALYSIS.md`; method in [PLAN.md](PLAN.md); the decoder used to read artifacts in [_shared/fvk-primer.md](_shared/fvk-primer.md); traceability in [INCIDENTS.md](INCIDENTS.md).*

## Macro context (the frame for everything below)

Across batch1–5, **the fvk arm and the baseline arm produced identical resolved/unresolved verdicts — zero flips.** FVK never converted a baseline failure into a pass (and never broke a baseline pass). The fvk arm is not an independent solver: it *forks the frozen baseline session*, starts from **V1 = base commit + baseline's patch**, and is told to *"audit that fix, then improve or confirm it,"* with no execution environment. So the question of this study is not "why didn't fvk solve it" but **"the V1 fix was already wrong/incomplete — did the FVK audit at least *contain* the root cause of the remaining failure?"**

The 11 failures span **6 repositories** (astropy ×1, django ×4, pytest ×1, sphinx ×1, xarray ×1, sympy ×3) — including symbolic-math (sympy) and array (xarray) domains added in batch5.

## Headline result

| Verdict | Count | Instances |
|---|---|---|
| **STATED** (root cause named in artifacts, then not acted on / argued against) | **4** | django-12325, pytest-10356, sympy-13852, sympy-16597 |
| **BURIED** (present only in formal scaffolding) | **0** | — |
| **MISSING** (no trace in artifacts; or inverted/certified-as-spec) | **7** | astropy-13398, django-10554, django-13212, django-16263, sphinx-9229, xarray-6992, sympy-18199 |

- **Root cause present in the FVK artifacts: 4 / 11 (≈36%).** All 4 are STATED.
- **All 7 MISSING cases are *reachable from public data*** (the issue text and/or the source the agent could read). **Zero** instances are MISSING because the bug falls in an FVK formal blind spot (primer §vi) — not even the symbolic-math sympy cases. The misses are *process* failures, not formal-power failures.
- **BURIED = 0 holds across all 11.** FVK does **not** hide the root cause as a forced precondition / undischarged obligation in the formal scaffolding. It either **names the fix and rejects it** (STATED) or **misses / inverts it** (MISSING). The "buried in formal noise" hypothesis did not materialize in any instance.

### Direct answer to the motivating question
The motivating hypothesis was: *"if ~half the failures already have their cause in the FVK artifacts, improving FVK could flip ~half."* Measured over 11: **≈36% (4/11), not ~50%.** See "Two senses of headroom" — the deeper result is more optimistic about the *ceiling* and more sobering about *what it takes to reach it*.

## The 4 STATED cases — one mechanism: localize, then reject the named fix via a self-imposed constraint

In every STATED case FVK **localized to the exact fix and named it**, then produced a *constructed (never machine-checked)* reason to keep the buggy behavior. The "self-imposed constraint" varies, but the shape is identical:

| Instance | Correct fix (named in artifacts) | The self-imposed constraint that rejected it |
|---|---|---|
| **django-12325** | `… and field.remote_field.parent_link` (one-liner, quoted verbatim) | an **existing pre-fix in-repo test** treated as binding — *the gold patch deletes that test* |
| **pytest-10356** | forward `obj.__mro__` (the whole bug is the token `reversed`) | a **fabricated "forcing" proof obligation** (PO3) asserting the buggy order is required, predicting the wrong hidden-test output |
| **sympy-13852** | put the `Li₂` special values in `polylog.eval` (+ golden-ratio coverage) | the issue's **pre-fix display** `Out[1]: polylog(2, 1/2)` read as a binding "stay-unevaluated" invariant; coverage dismissed as "enhancement" |
| **sympy-16597** | `irrational == real & finite & !rational` (quoted verbatim) | rejected as **"exceeds issue/hint scope"** |

**Lesson:** when FVK localizes, an over-conservative *"confirm V1 / preserve observed behavior / stay in issue-scope"* posture — backed by unchecked formal apparatus or deference to existing tests/displays — manufactures confident arguments *against* the correct fix. These 4 are the literal, defensible headroom: an FVK that trusted its own localized fix over a stale test / a pre-fix display / a self-constructed forcing-PO / a self-imposed scope fence would plausibly flip them **by acting on what it already produced.**

## The 7 MISSING cases — all reachable, all intent-fidelity / localization failures

None is blocked by FVK's formal limits; each is a failure to *localize to* or *formalize the intent of* the real defect. Sub-patterns (cross-referenced to primer tells):

- **Scope-induced false-negative / incomplete V1 ratified (tell #7)** — **astropy-13398**: V1 skipped `ITRS.location`, the CIRS/TETE bridges, and refraction; FVK drew the spec domain around the code that existed and declared it *"clean and total on its domain."*
- **Wrong scope/mechanism, decoy symptom-match** — **django-10554**: FVK formalized an unrelated `Query.clone()` aliasing contract, quoting the issue's error *string*, but never touched the true cause (a missing case in `get_order_by`).
- **Scope fence to the wrong file** — **django-13212**: FVK fenced all edits to `core/validators.py` and never opened `forms/fields.py` (the `DecimalField.validate` NaN short-circuit).
- **Certified the buggy output as the spec (tell #9 — "formalize the implementation, not the intent")** — four cases:
  - **django-16263**: a POSITIVE finding enshrines V1's wrong single-SELECT shape; the mini-ORM abstracts away the SQL-shape axis the tests measure.
  - **sphinx-9229** (half-fix): oracle needs two coordinated edits (`get_doc` + suppress the `alias of` line in `add_content`); V1 did only `get_doc`, and the artifacts certify rendering `alias of` *alongside* the doc-comment as intended; `add_content` is never audited.
  - **xarray-6992** (half-captured): a coupled two-part bug; FVK captured the `coord_names` half as a finding but the **graded-failure half** (the level-coord drop/convert loop) is abstracted into opaque `.k` sets, declared OUT-OF-SCOPE, and *proved "byte-for-byte unchanged."*
  - **sympy-18199** (half-captured): oracle co-ships a prime `a%p==0` zero-root fix (which V1 got, STATED) *and* composite-modulus support (the graded axis). FVK certifies the composite `NotImplementedError` as a "contract to preserve" (intent ledger L6, finding F6 [POSITIVE]); the composite fix appears nowhere.

**A batch5 refinement — "half-captured" coupled bugs.** xarray-6992 and sympy-18199 each co-ship *two* defects; FVK got the one the issue text spells out and **missed/inverted the one the graded test actually measures**. This generalizes django-13212's F3 lesson: localizing *a* real issue ≠ localizing *the graded* defect. Overall verdict is judged on the graded F2P → MISSING.

## The unifying thesis (now across 6 repos, 11 instances)

**The binding constraint on FVK's failure-flipping value is intent fidelity and localization — not formal expressiveness.** In 0/11 cases did the reach of K / matching-logic / invariants / circularity cause the miss; even the symbolic-math sympy bugs were process failures, not formal-power failures. The recurring mechanisms:

1. **The "confirm V1 / stay in issue-scope" framing** biases the agent to *ratify* the existing patch and to draw the audit boundary around the issue sentence rather than the full intent. It asks "is V1 sound on its domain?" — never "is V1 *complete* versus the whole intent?" (astropy-13398, sphinx-9229, sympy-18199, sympy-16597).
2. **"Formalize what the code does" drift** (which the kit forbids) yields specs whose postcondition *is* the buggy behavior, then certifies it POSITIVE (django-16263, sphinx-9229, xarray-6992, sympy-18199).
3. **Localization anchored to V1's files/diff, not the symptom** (django-10554, django-13212), and to *one* co-shipped defect rather than the graded one (xarray-6992, sympy-18199).
4. **Constructed, not machine-checked, proofs can fabricate** confident-but-false obligations that argue against the correct fix (pytest-10356; django-12325, sympy-13852 via over-trusted existing behavior).
5. **The mini-X fragment abstraction routinely drops the dimension the issue is about** (SQL shape, the forms layer, the level-coord loop) and then fences it as an escalation boundary — making the measured property invisible to the audit (django-16263, django-13212, xarray-6992).

## Two senses of "headroom" (stated honestly)

- **Narrow / defensible = 4 / 11 (≈36%).** The root cause is *already in the artifacts* (all STATED). An FVK that (a) trusted its own localized fix over a stale test / pre-fix display, (b) treated self-constructed "forcing" obligations skeptically, and (c) did not self-impose an issue-scope fence over a fix it had already named, would plausibly flip these four **by acting on information it already generated.**
- **Broad / contingent = up to 11 / 11.** Because **all** eleven are reachable from public data and **none** is a formal blind spot, a better-*steered* FVK could in principle reach the rest — but only via changes that improve **localization and intent-formalization**, which is more than "surface what's already there." A real opportunity, but a stronger and less certain claim.

## Prose directions to improve FVK (general, transferable, no-exec)

Derived from the patterns, not tuned to any single instance; batch5 sharpened #2 and added #7:

1. **Reframe the audit from "confirm V1 / stay in issue-scope" to "find what is still wrong versus the *full* intent."** Build the SPEC's intent ledger from the entire problem statement **and the docstring/API contract** — not the issue sentence alone — then require every intent clause to map to applied code. A clause the spec *excludes* ("no refraction", "composite p raises") is a divergence to flag, not settled scope. *(astropy-13398, sympy-16597, sympy-18199, sphinx-9229.)*
2. **Audit the whole function's behavior space, not just the diff or the "new branch."** A function-level postcondition must cover the *untouched* domain too; writing it forces the question "is this raise/output the intended contract or an unimplemented case?" *(xarray-6992, sympy-18199, astropy-13398.)*
3. **Formalize intent, not implementation; treat "the spec equals current output" as a red flag.** A POSITIVE finding that merely restates what the code does is not evidence of correctness. *(django-16263, sphinx-9229, xarray-6992, sympy-18199.)*
4. **Localize from the symptom, not from V1's diff — and target the *graded* defect.** Follow the issue's traceback/failing behavior to the function that produces it; when a fix co-ships multiple changes, check each against the tests. A symptom-string match around an unrelated mechanism is a decoy. *(django-10554, django-13212, xarray-6992, sympy-18199.)*
5. **Demote existing tests / displays / observed behavior from "binding ground truth" to "evidence that may be wrong."** When the issue implies current behavior is the bug, it must not veto the fix. *(django-12325, sympy-13852.)*
6. **Treat constructed proof obligations skeptically.** A "forcing" PO that *requires* the current behavior is as likely to be a fabricated rationalization as a real constraint; cross-check "the fix would break X" against whether X is actually a binding requirement. *(pytest-10356.)*
7. **Treat self-declared incompleteness markers as divergence candidates, not contracts.** A `NotImplementedError`, a `ConditionSet`/"can't solve" fallback, or a `raise` is a self-declared gap — the kit's own "if a clean spec is hard, suspect a bug" signal — and should become a *latent unhandled case*, never a `frame/preserve` invariant. *(sympy-18199.)*
8. **When the mini-X abstraction drops the dimension the issue is about (ordering, SQL shape, rendered output, a structural loop), that abstraction choice is itself the bug-hiding move.** Retain the property under test, or *flag that the audit cannot assess it* rather than certifying it. *(django-16263, django-13212, xarray-6992.)*

## Caveats / threats to validity

- **n = 11; repo mix broader but uneven** (django 4/11 ≈ 36%, sympy 3/11 ≈ 27%, plus astropy/pytest/sphinx/xarray ×1). Patterns held across all six repos and both new domains (symbolic math, arrays), but counts are not statistically strong.
- **Oracle-anchored, so "reachable" is judged with hindsight.** Mitigated by the PLAN §4 "pointed-at-the-spot" rubric and by restricting reachability to *public* data, not eliminated.
- **Eval-harness scoring caveat.** For django-13212 the per-test FAIL_TO_PASS *count* in `report.json` is inflated by a subtest-output parsing quirk (see INCIDENTS); the resolved/unresolved verdict — and thus the "zero flips" macro fact and our failing-set membership — is unaffected.
- **One headroom verdict was corrected during the run** (sympy-18199: a lead draft scored a MISSING case as "counts: YES"; corrected to NO per PLAN §4 — see INCIDENTS). The 4/11 figure reflects the corrected rubric.
- **FVK artifacts are "constructed, not machine-checked."** The proofs are LLM reasoning formatted as formal mathematics; "proved" means *argued*, not *verified*. Several failures (pytest-10356, django-16263, xarray-6992, sympy-18199) are downstream of exactly this.
