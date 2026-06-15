# sympy__sympy-16597 — ROUND-2 fvk audit (hardened materials)

**Run-id:** `fvk-improved-4cases-XC-MINI-PRO-AHP` · FVK materials submodule @ **275cd44** ("harden audit posture against rejecting a named correct fix").
**Arm result:** FAIL — FAIL_TO_PASS **0/3**; baseline identical; **zero flip** (sibling `pytest-10356` flipped; this one did not).
**Failing tests:** `test_infinity`, `test_neg_infinity`, `test_other_symbol`.
**FAILURE CLASS: PARTIAL (missing rules) — confirm-V1, no-act.** The hardened guidance changed the *reasoning* (round-1's verbatim "exceeds scope" rejection is gone; the agent now promotes the named fix to a falsifiable hypothesis) but **not the action**: the fvk patch is **byte-identical to V1** and adds only `rational -> real & finite`. The agent then re-rejected the named Axis-A fix on a **constructed and logically false** "positive ground," and **never even considered Axis B** (`algebraic`/`transcendental -> finite`) — which is what trips all three tests first.

**Round-1 -> round-2 delta.** R1 verdict was **STATED** (tell #8 strongest form + tell #9): the agent quoted the gold `irrational` edit verbatim, rejected it as "exceeds issue/hint scope," and certified the buggy value as a proved postcondition. R2: same patch, same 0/3, but the rejection rationale **migrated** from "scope" to a *manufactured* definition-fidelity/consistency argument (I6 + "B presupposes the forbidden `real => finite` change"). The hardening closed the exact loophole it targeted (scope-dropping) and the agent obediently re-routed around it. The buggy postcondition (tell #9) **persists unchanged** in the new `.k` artifacts.

---

## 1. Root cause (gold) — restated

sympy's **assumptions inference engine**. The declarative fact base had `even -> integer -> rational -> real` but **no edge to `finite`**, and `real` is the *extended* reals (`oo.is_real=True`), so `real` does NOT imply `finite`. Hence `Symbol('m', even=True).is_finite` returned `None`.

**Gold fix** adds `& finite` to **FOUR rules** in `sympy/core/assumptions.py :: _assume_rules`, **mirrors** them into the new-style engine `sympy/assumptions/ask.py :: get_known_facts()`, **and regenerates** `sympy/assumptions/ask_generated.py` (the CNF/dict caches):

```
rational       ->  real & finite                      # the integer tower (Axis-neutral base)
algebraic      ->  complex & finite                   # Axis B
transcendental ==  complex & !algebraic & finite      # Axis B
irrational     ==  real & !rational & finite          # Axis A
```

Two axes, both tested:
- **Axis A (irrational/infinity):** `irrational == real & !rational` is too weak. With only the integer-tower fix, `oo` becomes `real=True, rational=False, finite=False`, and the unchanged biconditional *forces* `oo.is_irrational=True`. Adding `& finite` makes the rule **not fire** for `oo` (it is `!finite`), so `oo.is_irrational` becomes `False`. **No `real` change is needed** — this is the key fact the agent got wrong.
- **Axis B (algebraic/transcendental):** `algebraic`/`transcendental` need `& finite` so `oo.is_algebraic` / `oo.is_transcendental` flip `None -> False`, and `Symbol(algebraic=True)` / `Symbol(transcendental=True)` gain `is_finite is True`.

**Bug type:** missing implication rules (incomplete fact base) — replicated across a **dual engine** (`assumptions.py` *and* `ask.py`) plus a **generated cache** (`ask_generated.py`).

**Public-data reachability: YES.** The defect, reproducer, and the literal first edit (`'rational -> real' -> 'rational -> real & finite'`) are in the issue/hint; the remaining three rules and the contrapositive `oo` consequences are fully derivable from the self-describing rule table.

---

## 2. What the round-2 fvk arm did — vs gold

**V1 vs final fvk: IDENTICAL — confirmed, not changed.** `md5(solution_baseline.patch) == md5(solution_fvk.patch) == a980a855...`; `diff` empty. The "13-line patch" is the *whole diff file* (headers + one substantive line). It is also identical to round-1's V1. The arm's only working-tree writes were the `fvk/*.k` and `fvk/*.md` artifacts. (`evidence/new_fvk_patch.diff`.)

**Precisely how it differs from gold** (`evidence/gold_patch_excerpt.diff`):
- It added `& finite` to **one** rule (`rational`), not **four**. **Missing:** `algebraic` (Axis B), `transcendental` (Axis B), `irrational` (Axis A).
- It **never opened** `sympy/assumptions/ask.py` or `sympy/assumptions/ask_generated.py` (transcript: 0 reads, 0 greps) — so even the dual-engine **mirror and the regenerated cache are entirely absent** from its consideration. (For *these three* FTP tests the proximate cause is the old-style rules, since the tests query `Symbol.is_*`; the dual-engine miss is a latent second gap, not the proximate failure here.)

**Key artifact contents (the new reasoning):**
- **fvk_notes Decision 2** (`:34-57`) — the agent *did* follow the new guidance: it cites `formalize.md S7` (spec-difficulty/verbal-rationalization heuristic) and `intent-evidence.md S5.8`, marks the legacy `oo.is_irrational is None` test **SUSPECT** (E8), and **promotes alternative B** (`irrational == real & !rational & finite`) to a falsifiable hypothesis. **But** it then "**rejects B on positive grounds**": "it contradicts the glossary definition `irrational == real & !rational` (I6) ... and is only coherent if `real => finite` — the very change I4/E5 forbid."
- **PROOF.md S4** two-column table (`:134-149`) hard-codes the false claim: B "presupposes the forbidden I4 change." (See S3 — this is logically wrong.)
- **ITERATION_GUIDANCE #1** (`:27-32`) — the agent **correctly names the true root cause** ("Extended reals (the real root cause) ... the principled long-term fix") but rules it "outside this issue," constructing a false dichotomy between the 1-line V1 edit and a large `extended_real` redesign — never seeing the gold middle path.
- **The `.k` mechanism persists (tell #9):** `mini-assume.k:92-96` still encodes the unfixed `irrational == real & !rational` (no `finite` premise) -> fires for `oo`; `assume-spec.k:80` asserts `irrational |-> true` as the proved OO-CONSISTENT fixpoint, "discharged" by PROOF S2/S4. The buggy value is again blessed as proved.
- **Axis B is absent everywhere:** `mini-assume.k` has no `algebraic`/`transcendental`/`complex` atoms; no finding, claim, PO, or transcript line proposes `algebraic/transcendental -> finite`.

---

## 3. Diagnosis (the heart) — WHY the action is wrong

The 0/3 has **two coupled gaps**, both flowing from one meta-failure (formalizing/auditing only the rule *slice* the issue sentence names, against the pre-fix tests the agent could see):

**(a) Axis B is simply never on the table.** The eval tracebacks (`evidence/failing_FTP_tests.txt`) show the *first* assertion to trip in each test:
- `test_infinity:103` -> `assert oo.is_algebraic is False` (**AssertionError**; V1 yields `None`).
- `test_neg_infinity:130` -> `assert mm.is_algebraic is False` (**AssertionError**).
- `test_other_symbol:630` -> `assert x.is_finite is True` where `x = Symbol('x', transcendental=True)` (**AssertionError**; V1 yields `None`).

All three are **Axis B**. V1's `rational -> real & finite` covers the integer/even/rational symbol cases (those assertions pass) but does nothing for `algebraic`/`transcendental`. The agent modeled `even/integer/rational` only, so its proof "discharged the reported intent I1-I3" while the tests demand the *symmetric* edges it never wrote. There was **no smell** to trip its heuristics here: a *missing positive flip* (`None -> False`/`None -> True`) on `algebraic`/`transcendental` produces no awkward case-split, no forced side condition, no "conventionally wrong" phrase — so even the hardened spec-difficulty rule stayed silent. The agent needed to *generalize* "the issue is `even` but the fix lives in the rational/finite rule family" to "audit the WHOLE finite-implying predicate family"; it did not.

**(b) Axis A: the named fix was promoted, then killed by a false proof.** Here the hardening *did* engage (Decision 2 promotes B), so this is no longer R1's bare scope-drop. But the agent rejected B on a **constructed argument that is provably false**: it claimed B "is only coherent if `real => finite`." It is not. `irrational == real & !rational & finite` does not fire for `oo` precisely because `oo.is_finite=False`, so it yields `oo.is_irrational=False` with **no clash and no change to `real`** — exactly what the gold patch does and what the gold tests require. The agent's own `.k` semantics would have demonstrated this had it added the `finite` premise to the `mini-assume.k:92` rule; instead it kept the unfixed rule and "proved" `irrational=true`. This is **primer tell #8's broader form** (a named correct fix rejected on a *constructed* argument) co-occurring with **tell #9** (the buggy value certified as the spec) — both surviving into the hardened-materials world because the rejection no longer says the forbidden word "scope."

**Root enabler — the no-execution + hidden-test blind spot (unchanged from R1).** Transcript msg 38 shows the agent read `test_assumptions.py` at the **base commit**, where line 103 reads `assert oo.is_algebraic is None` and the irrational/transcendental rows likewise show pre-fix `None`. The gold test_patch (flipping these to `False`/`True`) is applied only at eval time. So the agent's entire "consistency / definition-faithfulness" frame was calibrated to legacy assertions; it literally could not see that the hidden tests demand the Axis-A/B flips. The hardening's "mark SUSPECT" rule rescued the *one* `irrational` row whose post-fix value the agent could *derive* as a smell — but it cannot conjure the Axis-B `algebraic`/`transcendental` expectations, which are invisible without either running the (updated) tests or generalizing the rule family from first principles.

**Classification: PARTIAL (missing rules: Axis B entirely + Axis A's `& finite`; plus the latent ask.py/ask_generated.py mirror miss).** Not WRONG-LOCATION (the one edit is in the right file/function). Not OVER-REACH (PASS_TO_PASS 76/76 intact). The specific gap: **the fix family was under-applied — 1 of 4 rules — and the parallel engine + generated cache were never inspected.**

---

## 4. How FVK materials could close the gap (round-3 recommendation)

Round-2 proves the round-1-style guidance (don't drop a named fix on scope) **necessary but not sufficient**: the agent re-routed the rejection through a constructed proof and, more importantly, never *generated* the Axis-B candidate at all. Two general, transferable, no-exec material changes:

**(R3-1) "Formalize the whole rule/relation family the fix touches — and find its duplicated engines and generated mirrors." (NEW; the dominant lever.)** Add to `commands/formalize.md` (intent-ledger / scoping step): *when the fix edits one member of a structurally homogeneous family (a row in a rule table, one case of an enum/dispatch, one branch of a biconditional set), enumerate the sibling members and ask of EACH the same obligation the issue asks of the named one; a sibling that would need the same edit but is left untouched is a Finding, not out of scope.* And: *after editing a declarative table, grep for parallel implementations and generated/cached artifacts of the same facts (e.g. a second engine, a `*_generated.py`, a compiled CNF) and assert the edit is mirrored; an un-mirrored duplicate is a latent defect.* This directly manufactures the missing `algebraic`/`transcendental -> finite` edges and the `ask.py`/`ask_generated.py` mirror — the gold patch is literally "the same `& finite` applied across the whole family in both engines." General value: rule-table / dual-engine / generated-file bugs are a common SWE-bench shape.

**(R3-2) "A constructed 'positive ground' for rejecting a named fix must itself be discharged against the candidate's own semantics — re-derive the candidate's behavior before declaring it incoherent." (Strengthens verify.md:62's balance clause.)** The agent's escape hatch was the "Balance: it may still be rejected on positive intent grounds" clause; it used it with a *false* claim ("B presupposes `real => finite`"). Add: *if you reject a promoted candidate because it "requires / presupposes / contradicts" some other property, you must run the candidate through the same `.k`/closure derivation you ran for V1 and exhibit the contradiction concretely; a rejection asserted at the prose level, without re-deriving the candidate's fixpoint, is not a valid positive ground.* Had the agent put `finite` into the `mini-assume.k` irrational rule and re-closed `oo`, it would have seen `irrational` does not fire -> no clash -> B is consistent. This converts the constructed-proof risk (tell #8 broad form) into a checkable obligation.

**(Supporting) Re-state tell #9 as a gate:** *a postcondition the proof asserts for a singleton (`oo.is_irrational=true`) that the artifact's own prose calls "conventionally wrong" must be treated as a candidate defect, not discharged as "consistent / definitional."* (R2 still violated this.)

**Closable by materials? PARTIAL.** Axis A is fully material-fixable: R3-2 forces the agent to falsify its own incoherence claim and accept B. The dominant Axis B is fixable in principle by R3-1 (family-enumeration generates the candidate), **but** the *value* the hidden tests demand (`oo.is_algebraic is False`) remains unverifiable without execution — the agent would propose `algebraic -> complex & finite` from family-symmetry and mathematical reasoning (infinity is not algebraic), which is correct, yet under no-exec it cannot confirm the test will pass. So R3-1 raises the *probability* of the flip substantially without guaranteeing it. **Headroom: real but capped by the no-execution + hidden-test blind spot** — the same structural ceiling identified across this study. This is an *intent/scope-fidelity + fix-completeness* failure (the agent localized correctly and named the true root cause), not a formal-expressiveness limit.
