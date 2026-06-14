# sympy__sympy-16597 — FVK artifact audit

**Batch:** `batch5-XC-MINI-PRO-AHP-260614105258` · **Arm result:** FAIL (FAIL_TO_PASS 0/3; baseline identical; zero flips).
**Failing tests:** `test_infinity`, `test_neg_infinity`, `test_other_symbol`.
**VERDICT: STATED** (counts toward headroom). Primer tell #8 ("STATED-but-reasoned-against") in its strongest form — FVK quotes the gold fix verbatim and rejects it as "out of scope," and its formal spec claim *asserts the buggy value as the proved postcondition*.

---

## 1. Root cause

This is sympy's **assumptions inference engine** (predicates `is_finite`/`is_infinite`/`is_even`/`is_integer`/`is_rational`/`is_irrational`/`is_algebraic`/`is_transcendental` and the implication rules between them). Issue title: *"a.is_even does not imply a.is_finite."*

The declarative fact base had a chain `even -> integer -> rational -> real` but **no edge to `finite`**, and crucially `real` does *not* imply `finite` (sympy's `real` is the *extended* reals — `oo`/`-oo` are `is_real=True`). So `Symbol('m', even=True).is_finite` returned `None` instead of `True`.

**Exact gold fix** (`logs/run_evaluation/...goldcheck/gold/sympy__sympy-16597/patch.diff`) — adds `& finite` to four rules in **`sympy/core/assumptions.py`** `_assume_rules`:
```
'rational       ->  real & finite'
'algebraic      ->  complex & finite'
'transcendental ==  complex & !algebraic & finite'
'irrational     ==  real & !rational & finite'
```
...mirrored in the **new-style engine** `sympy/assumptions/ask.py` `get_known_facts()` (`Implies(Q.irrational, Q.finite)`, `Implies(Q.algebraic, Q.finite)`, `Implies(Q.transcendental, Q.finite)`, `Equivalent(Q.irrational | Q.rational, Q.real & Q.finite)`, etc.) and the regenerated `sympy/assumptions/ask_generated.py` caches. (Two incidental, test-irrelevant edits: a `Pow._eval_is_rational` perf guard and an `Idx` +-oo-bounds fix.)

**Bug TYPE:** missing implication rules (incomplete fact base). Two distinct axes:
- **Axis A (irrational/infinity)** — the biconditional `irrational == real & !rational` is too weak: it must gain `& finite`. Without it, `oo` (real=True, rational=False after `rational->finite` is added, finite=False) is *forced* to `is_irrational=True`. This is what breaks `test_infinity`/`test_neg_infinity`.
- **Axis B (algebraic/transcendental)** — `algebraic`/`transcendental` also need `& finite` so that `oo.is_algebraic`/`oo.is_transcendental` flip `None->False`.

**What the failing tests assert** (`evidence/failing_tests_snippet.txt`): `test_infinity`/`test_neg_infinity` require `oo`/`-oo` `.is_integer/.is_rational/.is_algebraic/.is_transcendental/.is_irrational/.is_even/.is_odd/.is_composite` all `is False` and `.is_noninteger is True`. `test_other_symbol` requires `Symbol(even=True/odd=True/integer=True/rational=True/irrational=True).is_finite is True` (the negative `even=False` etc. correctly stay `None`).

**Public-data reachability: YES.** The problem statement states the defect exactly and gives a reproducer; the fix lives in a self-describing declarative table (`'rational -> real'`, `Implies(...)`). The contrapositive consequence on `oo.is_irrational` is fully derivable from the rule semantics (and FVK *did* derive it — see section 2).

---

## 2. What the fvk arm did

**V1 vs final: IDENTICAL — confirmed, not changed.** `solution_baseline.patch` and `solution_fvk.patch` are byte-for-byte equal (md5 `3e30b9e0...`; `evidence/patch_diff_v1_vs_final.txt`). Both add exactly one rule: `'rational -> finite'` in `assumptions.py`. The arm's only working-tree writes were the `fvk/*.k` and `fvk/*.md` artifacts. So V1 fixes `test_other_symbol`'s even/integer/rational cases but leaves both infinity tests failing and the algebraic/transcendental assertions unmet -> 0/3.

**Key artifact contents.** FVK correctly proved the easy half (PO1-PO3: even/integer/rational => finite; `mini_assumptions-spec.k:35-64`). It then *correctly predicted the test-breaking flip* and chose to leave it. The decisive contents:

- **FINDINGS F2** (`fvk/FINDINGS.md:21-43`) names the post-fix value `oo.is_irrational=True`, admits "*Conventionally an infinity is not an irrational number*," tags it "accepted consequence," and in `:42` names the gold fix verbatim — *"redefining `irrational == real & finite & !rational`"* — then rejects it: *"changes `irrational` for ordinary symbols and exceeds the issue/hint scope (L3/L4)."*
- **`reports/fvk_notes.md` Decision 4** (`:41-53`): *"do NOT modify `irrational == real & !rational`... redefining `irrational == real & finite & !rational` changes `irrational` for ordinary symbols and exceeds the issue/hint scope (L3/L4)... leave `irrational` alone and record `oo.is_irrational=True` as an accepted consequence."*
- **FINDINGS bottom line** (`:111-113`): *"the audit surfaced no correctness defect in V1... V1 stands."*
- **F6** (`:79-90`): treats the deeper problem as a `real -> finite` redesign requiring a new `extended_real` predicate (a "large, breaking change"), thereby *over-scoping* the fix — the gold patch only needed `& finite` conjuncts, not an `extended_real` redesign.

**The `.k` implication rules** (the mechanism, per primer section v "skim the `.k`"):
- **BUGGY beta rule** `mini_assumptions.k:127-132`:
  ```
  //  irrational == real & !rational   ==>  beta:  real & !rational -> irrational
  rule <k> checkBeta => tell(irrational, true) ... </k>
       <kb> KB </kb>
    requires (real in_keys(KB)) andBool (KB[real] ==K true)
     andBool (rational in_keys(KB)) andBool (KB[rational] ==K false)
     andBool (notBool (irrational in_keys(KB)))
  ```
  This encodes the *unfixed* biconditional — no `finite` premise — so for `oo` it FIRES -> `irrational=true`. It is the formal embodiment of the exact defect. The gold rule (`& finite`) would not fire.
- **DECISIVE spec claim** `mini_assumptions-spec.k:77-86` (PO5 CONSISTENT-OO) *asserts the buggy value as the proved postcondition*:
  ```
  claim <k> tell(positive, true) tell(infinite, true) close => .K ... </k>
        <kb> .Map => ?KB:Map </kb>  <status> ok </status>
    ensures ... andBool (irrational in_keys(?KB)) andBool (?KB[irrational] ==K true)   // F2: forced, consistent
  ```
  `PROOF.md section 4` then "discharges" this claim. (Its other conjuncts — `finite=false, rational=false, integer=false, even=false, noninteger=true` — all match gold; only the `irrational ==K true` conjunct is the defect.)
- The model has **no `algebraic`/`transcendental` facts at all** (`SPEC.md section 3`, `:73-76` admits it "models only the fact slice the claims need"), and the agent **never opened `ask.py`/`ask_generated.py`** (0 reads/greps in transcript) — Axis B is absent from the formalization.

---

## 3. Artifact audit — VERDICT

**VERDICT: STATED** (counts toward headroom: **yes**).

The "pointed-at-the-spot" test is met decisively on the *cause*, not a symptom string. This is primer tell #8 in its strongest variant: **the artifact names the oracle's exact fix and argues against it**, and additionally tell #9 (FVK *certifies the buggy behavior as the spec*). A knowledgeable reader pointed at these lines would agree the correct fix is right there:

> **Exact excerpt (the fix, named and rejected):** `fvk/FINDINGS.md:42` and `reports/fvk_notes.md:48` —
> *"redefining `irrational == real & finite & !rational`, which changes `irrational` for ordinary symbols and exceeds the issue/hint scope (L3/L4)."*
> This is verbatim the gold change (`sympy/core/assumptions.py: 'irrational == real & !rational & finite'`).

> **Exact excerpt (the buggy value blessed as proved):** `fvk/mini_assumptions-spec.k:84` —
> `andBool (irrational in_keys(?KB)) andBool (?KB[irrational] ==K true)   // F2: forced, consistent`
> The gold-updated `test_infinity`/`test_neg_infinity` require `oo.is_irrational is False`. The spec's own postcondition is the failing value.

**Why STATED, not BURIED:** the signal is not merely latent in formal scaffolding — it is surfaced in *plain language* as a named finding (F2) and an explicit logged decision (Decision 4) that quotes the correct fix. FVK localized perfectly and *held the answer*; the failure was acting on it. The rejection rests on two constructed errors: (a) **over-trusting scope** — treating the hint's deferral of a broad `extended_real` redesign as forbidding the narrow `& finite` conjunct the gold patch actually used; (b) **the no-execution + hidden-test blind spot** — FVK reasoned "is the new state *consistent*?" (yes) instead of "is `oo.is_irrational=True` *what the tests will demand*?" (no), because it could not see the test would be updated to assert `is False`. This matches the calibration: an *intent-fidelity* failure (FVK argued itself out of the fix via over-trusting current behavior/scope as binding), not a formal-expressiveness limit, fully reachable from public data.

**Scope note (Axis B):** the `algebraic`/`transcendental -> finite` half (also tested) is genuinely **MISSING** from the model — never formalized, `ask.py` never read. But the dominant decisive axis (irrational/infinity, 2 of the 3 failing tests, and the most-cited finding) is STATED, and STATED dominates the overall verdict: had FVK acted on its own F2/Decision-4 signal *and* generalized the same `& finite` insight it explicitly wrote down, all three tests flip. The presence of the correct fix in the artifacts is not in doubt.

**Confirmed absences searched:** no `[ESCALATION BOUNDARY]` markers anywhere (`manifest.json` `marker_warnings: []`); all proof obligations marked discharged (including the buggy PO-C1/PO5); no undischarged VC sits on the buggy branch — instead the buggy branch is *affirmatively proved correct*.

---

## 4. How FVK could surface it (prose, general, no-exec)

1. **Distinguish "consistent" from "intended."** PO5 proved the new `oo` state raises no contradiction and stopped. The kit's own day-one heuristic — *"if a clean spec is hard to write, the code has a bug"* — should have fired on F6: the difficulty of cleanly excluding `oo` from `irrational` *is* the bug signal, not an "accepted consequence." A surfacing rule: when a forced determination (`oo.is_irrational=True`) is flagged as conventionally-wrong in prose (F2 literally says so), escalate it to a candidate defect rather than discharging it as "consistent."

2. **Don't let `requires`/scope launder the fix away.** FVK derived the exact gold edit and rejected it on a *scope* argument built from the issue hint. A general guard (mirrors tell #8): when an artifact *names a concrete fix and rejects it*, that fix must be promoted to a tested hypothesis, never silently dropped — especially under hidden tests where "current/expected behavior" cannot be confirmed.

3. **Formalize the whole rule family the fix touches, not a slice.** The model omitted `algebraic`/`transcendental` and never read the parallel `ask.py` engine, so Axis B was unrepresentable. A spec that captured *all* predicates implying `finite` (a single "finite-number" super-predicate) would have exposed the symmetric missing edges and the dual-engine duplication.

4. **Re-derive the property the spec asserts, both polarities.** PO5 asserted `irrational ==K true` for `oo`; a "challenge the postcondition against documented intent" step (intent: "an infinity is not irrational") would have caught the divergence the spec itself encoded.
