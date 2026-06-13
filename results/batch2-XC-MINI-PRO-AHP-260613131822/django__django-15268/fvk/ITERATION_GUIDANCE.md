# ITERATION_GUIDANCE.md — django__django-15268

Feedback package for the next code/spec/test pass. Each item: the evidence, a
classification, the UltimatePowers-style question for the user, and the recommended
next action.

---

## Decision for this iteration: **V1 stands, unchanged.**

The audit discharged every behavioural obligation (PO-COLLAPSE, PO-FIX, PO-DIFFMODEL,
PO-SCOPE, PO-COMMUTE, PO-TERM). The two residuals are a non-triggering invariant
(PO-NOSHADOW) and a proof-capability boundary (PO-OPT-SOUND) — neither is a code defect.
No source edit is justified by the FVK artifacts; making one would be unmotivated churn.

---

## G1 — Keep the fix gated on the base class, not on a kind pair
- **Evidence:** PO-SCOPE / F3. The `isinstance(operation, AlterTogetherOptionOperation)`
  gate is what preserves the #31503 remove/add split.
- **Classification:** design constraint to protect.
- **Question for the user:** "Are `AlterUniqueTogether` and `AlterIndexTogether` the only
  intended `AlterFooTogether` operations, or might more be added?"
- **Next action:** if a new subclass is ever added, re-discharge **PO-COMMUTE** for it
  (does its `state_forwards`/`database_forwards` touch an option/DB object disjoint from
  the others?). The blanket `True` is sound **iff** every pair of distinct-kind
  same-model together-ops commutes. Document this requirement on the base class.

## G2 — The `or []` shadowing invariant is latent; guard it only if the chain changes
- **Evidence:** PO-NOSHADOW / F4. `super().reduce()` never returns `[]` today, so the
  `or` is safe; the idiom matches `ModelOperation.reduce`/`RenameModel.reduce`.
- **Classification:** documented invariant (not a bug).
- **Question for the user:** "Should the `reduce` protocol forbid returning an empty list
  from the `ModelOperation`/`ModelOptionOperation` chain, or is that a meaningful
  ‘delete both’ signal we must tolerate?"
- **Next action:** none now. If any `AlterFooTogether`-reachable `reduce` is later changed
  to return `[]`, switch the idiom to an explicit `is not False` test to avoid the
  shadowing, and add a regression test for the empty-list verdict.

## G3 — Close PO-OPT-SOUND whole-list with a machine-checked proof or keep the integration test
- **Evidence:** PO-OPT-SOUND / F6 `[ESCALATION BOUNDARY]`. Whole-list semantic
  equivalence needs list induction + a `ProjectState`/`SchemaEditor` model.
- **Classification:** proof-capability gap.
- **Question for the user:** "Is an end-to-end optimizer test acceptable as the witness
  for whole-list soundness, or do you want the machine-checked reachability proof?"
- **Next action:** keep the interleaved-optimization integration test (PROOF.md §6). To
  upgrade from *constructed* to *machine-checked*, escalate via
  `knowledge/sources.md` (FM 2012 / LICS 2013 reachability induction; multiset reasoning
  for the DB-effect log) and run the `kprove` commands in PROOF.md §7.

## G4 — Tests: keep all; remove none yet
- **Evidence:** PROOF.md §6, honesty gate.
- **Classification:** test-redundancy (benefit 1), conditioned.
- **Next action:** keep `test_alter_alter_*` (different code path) and the new interleaved
  test (escalated domain). Revisit removals only after `kprove` returns `#Top` on the
  REDUCE-\*/COMMUTE/OPT-TERM claims — and even then the integration test stays.

---

## One-line summary for the next generator

The fix is correct and minimal; **do not regenerate it.** Preserve the
`isinstance(..., AlterTogetherOptionOperation)` gate and the `super().reduce() or (…)`
idiom; the only open items are an escalated whole-list proof and a dormant
empty-list-shadowing invariant, both tracked, neither requiring a code change.
