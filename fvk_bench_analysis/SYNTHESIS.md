# SYNTHESIS — FVK improvement headroom on batch1–4 failures

*Cross-instance synthesis of all 7 fvk-failing instances in batch1–4. Per-instance detail in each `<instance_id>/ANALYSIS.md`; method in [PLAN.md](PLAN.md); the decoder used to read artifacts in [_shared/fvk-primer.md](_shared/fvk-primer.md); traceability in [INCIDENTS.md](INCIDENTS.md).*

## Macro context (the frame for everything below)

Across batch1–4, **the fvk arm and the baseline arm produced identical resolved/unresolved verdicts — zero flips.** FVK never converted a baseline failure into a pass (and never broke a baseline pass). The fvk arm is not an independent solver: it *forks the frozen baseline session*, starts from **V1 = base commit + baseline's patch**, and is told to *"audit that fix, then improve or confirm it,"* with no execution environment. So the question of this study is not "why didn't fvk solve it" but **"the V1 fix was already wrong/incomplete — did the FVK audit at least *contain* the root cause of the remaining failure?"**

## Headline result

| Verdict | Count | Instances |
|---|---|---|
| **STATED** (root cause named in artifacts, then not acted on / argued against) | **2** | django-12325, pytest-10356 |
| **BURIED** (present only in formal scaffolding) | **0** | — |
| **MISSING** (no trace in artifacts) | **5** | astropy-13398, django-10554, django-13212, django-16263, sphinx-9229 |

- **Root cause present in the FVK artifacts: 2 / 7 (≈29%).** Both are STATED.
- **All 5 MISSING cases are *reachable from public data*** (the issue text + the source the agent could read). **Zero** instances are MISSING because the bug falls in an FVK formal blind spot (primer §vi). The misses are *process* failures, not formal-power failures.
- **BURIED = 0 is itself a finding:** for these instances FVK does **not** tend to hide the root cause as a forced precondition / undischarged obligation in the formal scaffolding. It either **names the fix and rejects it** (STATED) or **misses entirely** (MISSING). The "buried in formal noise" hypothesis did not materialize here.

### Direct answer to the motivating question
The motivating hypothesis was: *"if ~half the failures already have their cause in the FVK artifacts, improving FVK could flip ~half."* Measured: **~29% (2/7), not ~50%.** But see "Two senses of headroom" — the deeper result is more optimistic about the *ceiling* and more sobering about *what it takes to reach it*.

## The 2 STATED cases — FVK had the answer and formally argued itself out of it

Both cases show FVK **localizing to the exact fix**, then producing a *constructed (never machine-checked)* argument that endorses the bug:

- **django-12325** — `FINDINGS.md` F-4 quotes the oracle's one-line fix verbatim (`… and field.remote_field.parent_link`), calls it "the tempting one-liner," and **rejects it because it would break a pre-fix in-repo test** — a test the gold patch *deletes*. FVK treated an existing test as binding ground truth.
- **pytest-10356** — the entire bug is one token (`reversed(obj.__mro__)` vs forward). FVK audited exactly the ordering question and **manufactured a flawed "forcing" proof obligation (PO3)** asserting the buggy order is *required*, even predicting the wrong hidden-test output (`[b,a,c]`, the inverse of the needed `[c,a,b]`). The "compatibility" argument is provably false (the cited P2P tests pass under both orders).

**Lesson:** when FVK localizes, its unchecked formal apparatus and its deference to existing tests can fabricate confident arguments *against* the correct fix. These 2 are the literal, defensible headroom: an FVK that trusted its own localized fix over a stale test / self-constructed forcing-PO would plausibly flip them **by surfacing and acting on what it already produced.**

## The 5 MISSING cases — all reachable, all intent-fidelity / localization failures

None is blocked by FVK's formal limits; each is a failure to *localize to* or *formalize the intent of* the real defect. Sub-patterns (cross-referenced to primer tells):

- **Scope-induced false-negative / incomplete V1 ratified (tell #7)** — **astropy-13398**: V1 added one new file but skipped the `ITRS.location` attribute, the CIRS/TETE bridges, and refraction. FVK drew the spec domain around the code that existed and declared the contract *"clean and total on its domain"* — false reassurance. The defect (and the exact fix pattern) were in the public issue and in source the agent opened.
- **Wrong scope/mechanism, decoy symptom-match** — **django-10554**: FVK formalized an unrelated `Query.clone()` aliasing contract and quoted the issue's error *string*, but never touched the true cause (a missing case in `get_order_by`).
- **Scope fence to the wrong file** — **django-13212**: FVK fenced all edits to `core/validators.py` and never opened `forms/fields.py`, where the graded failure's cause (`DecimalField.validate` NaN short-circuit) lives.
- **Certified the buggy output as the spec (tell #9 — "formalize the implementation, not the intent")** — **django-16263** (a POSITIVE finding enshrines V1's wrong single-SELECT shape; the mini-ORM abstracts away the SQL-shape axis the tests measure and fences it as an escalation boundary) and **sphinx-9229** (a "half-fix": oracle needs two coordinated edits, `get_doc` + suppressing the `alias of` line in `add_content`; V1 did only `get_doc`, and the artifacts certify rendering `alias of` *alongside* the doc-comment as the intended spec; `add_content` is never audited).

## The unifying thesis

**The binding constraint on FVK's failure-flipping value in this sample is intent fidelity and localization — not formal expressiveness.** K/matching-logic power, invariants, and circularity were never the bottleneck; in fact in 0/7 cases did the formalism's reach (or lack of it) cause the miss. The recurring mechanisms:

1. **The "confirm V1" framing** biases the agent to *ratify* the existing patch. It asks "is V1 sound on its domain?" — never "is V1 *complete* versus the issue?" (astropy-13398, sphinx-9229).
2. **"Formalize what the code does" drift** (which the kit explicitly forbids) yields specs whose postcondition *is* the buggy behavior, then certifies it as POSITIVE (django-16263, sphinx-9229).
3. **Localization is anchored to V1's files, not to the symptom.** The spec domain is drawn around the code that exists or the wrong module, so the defect is never represented (django-10554, django-13212).
4. **Constructed, not machine-checked, proofs can fabricate** confident-but-false obligations that argue against the correct fix (pytest-10356; django-12325 via an over-trusted test).
5. **The mini-X fragment abstraction routinely drops the very dimension the issue is about** (SQL shape, rendering layer) and then fences it as an escalation boundary — making the measured property invisible to the audit (django-16263, django-13212).

## Two senses of "headroom" (stated honestly)

- **Narrow / defensible = 2 / 7 (≈29%).** The root cause is *already in the artifacts* (both STATED). An FVK that (a) trusted its own localized fix over a stale in-repo test, and (b) treated self-constructed "forcing" obligations skeptically, would plausibly flip these two **by acting on information it already generated.** This is the literal answer to "is the root cause in the FVK artifacts?"
- **Broad / contingent = up to 7 / 7.** Because **all** seven are reachable from public data and **none** is a formal blind spot, a better-*steered* FVK could in principle reach the rest — but only via changes that improve **localization and intent-formalization**, which is more than "surface what's already there." This is a real opportunity, but a stronger and less certain claim; do not over-read it.

## Prose directions to improve FVK (general, transferable, no-exec)

Derived from the patterns above, not tuned to any single instance:

1. **Reframe the audit from "confirm V1" to "find what is still wrong versus the issue's full intent."** Build the SPEC's intent ledger from the *entire* problem statement — error tracebacks, "I have yet to add X" admissions, worked examples — then require every intent clause to map to applied code. A clause the spec *excludes* ("no refraction") is a divergence to flag, not settled scope. *(astropy-13398, sphinx-9229.)*
2. **Formalize intent, not implementation; treat "the spec equals current output" as a red flag.** A POSITIVE finding that merely restates what the code does is not evidence of correctness. *(django-16263, sphinx-9229.)*
3. **Localize from the symptom, not from V1's diff.** Follow the issue's traceback to the function that produces the symptom; do not fence the audit to the files V1 happened to touch. A symptom-string match wrapped around an unrelated mechanism is a decoy. *(django-10554, django-13212.)*
4. **Demote existing in-repo tests from "binding ground truth" to "evidence that may be wrong."** When the issue implies a test encodes the bug, that test must not veto the fix. *(django-12325.)*
5. **Treat constructed proof obligations skeptically.** A "forcing" PO that *requires* the current behavior is as likely to be a fabricated rationalization as a real constraint; cross-check any "the fix would break X" claim against whether X is actually a binding requirement. *(pytest-10356.)*
6. **When the mini-X abstraction drops the dimension the issue is about (ordering, SQL shape, rendered output), that abstraction choice is itself the bug-hiding move.** The model must retain the property under test — or the audit must *flag that it cannot assess the relevant behavior* rather than certifying it. *(django-16263, django-13212.)*

## Caveats / threats to validity

- **Small n (7), Django-heavy (4/7).** Patterns held across astropy/django/pytest/sphinx, but the counts are not statistically strong.
- **Oracle-anchored, so "reachable" is judged with hindsight.** Mitigated by the PLAN §4 "pointed-at-the-spot" rubric and by restricting reachability to *public* data, but not eliminated.
- **Eval-harness scoring caveat.** For django-13212 the per-test FAIL_TO_PASS *count* in `report.json` is inflated by a subtest-output parsing quirk (see INCIDENTS); the resolved/unresolved verdict — and thus the "zero flips" macro fact and our failing-set membership — is unaffected.
- **FVK artifacts are "constructed, not machine-checked."** The proofs are LLM reasoning formatted as formal mathematics; "proved" means *argued*, not *verified*. Several failures (pytest-10356, django-16263) are downstream of exactly this.
