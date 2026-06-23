# django__django-15268

## Summary

**Severity:** Low — baseline's new `AlterTogetherOptionOperation.reduce()` returns
`True` for the cross together-option case *before* consulting the inherited
reducer, so it can shadow a non-`False` reduction the parent classes would have
produced; the residual only bites a narrow optimizer-composition path, not
runtime database correctness.

Baseline's core fix is correct: the reported optimizer failure (a split
`AlterUniqueTogether` / `AlterIndexTogether` remove/add sequence that never
collapses) is genuinely repaired, and the baseline patch passed the official
SWE-bench evaluation. The residual is purely in *ordering* within the new
`reduce()` override: baseline checks the cross-option transparency rule first and
short-circuits with `True`, which can lose an inherited non-`False` reduction
(e.g. an elidable or same-option result) from the parent reducer. FVK located
this by formalizing "preserve inherited reductions" as obligation PO-1 and moved
the `super().reduce()` consultation ahead of the new rule in V2.

| Arm | Cross together-option collapse works; inherited non-`False` reductions preserved | Resolved |
|---|---|---|
| baseline | Split sequence collapses; but new rule returns `True` before consulting `super().reduce()` | partial |
| gold (human oracle) | Split sequence collapses; reduction scoped to the together-option family | yes |
| **fvk** | Split sequence collapses; `super().reduce()` consulted first, new rule only when parent is `False` | yes |

## 1. The issue and the real defect

The issue is *"Optimize multiple AlterFooTogether operations into one"*: the
migration optimizer cannot reduce a split sequence that clears both together
options and then re-adds their final values. The example given is that
`[U(m,set()), I(m,set()), U(m,{col}), I(m,{col})]` should optimize to
`[U(m,{col}), I(m,{col})]`
([`prompts/fvk.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/prompts/fvk.md#L2),
issue text quoted in
[`fvk/SPEC.md` INT-1/INT-4](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/SPEC.md#L24)).

The root cause is that `AlterUniqueTogether` and `AlterIndexTogether` inherit
`ModelOptionOperation.reduce()`, which only collapses operations of the *same*
concrete class on the same model. Each together option therefore treats the
*other* together option on the same model as a blocking model reference, so the
optimizer cannot move the same-option remove/add pairs together
([`reports/baseline_notes.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/reports/baseline_notes.md#L5),
[`fvk/FINDINGS.md` F-002](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L15)).
The user-facing observable is migration files with four redundant
`AlterFooTogether` operations where two would suffice.

## 2. Baseline's fix — and where it stopped

Baseline's diagnosis is correct, and so is the shape of its fix. It adds an
`AlterTogetherOptionOperation.reduce()` override that returns `True` when the
compared operation is the *other* together option on the same model, letting the
optimizer pass through it and then collapse the repeated same-option operations
([`solutions/solution_baseline.patch`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/solutions/solution_baseline.patch#L9)).
Its scoping reasoning is deliberate, and it consciously rejected the broader
alternative:

> *"I considered changing `ModelOptionOperation.reduce()` to allow all different
> model option operations on the same model to pass through each other, but
> rejected that as too broad. … The change is limited to `AlterUniqueTogether`
> and `AlterIndexTogether`, which are the two split `AlterFooTogether` operations
> described in the issue."*
> — [`reports/baseline_notes.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/reports/baseline_notes.md#L19)

That scoping is sound, and for the reported symptom the fix works. The gap is in
the *ordering* inside the new override. Baseline checks the cross-option case
first and returns `True` before ever calling the parent reducer, falling through
to `super().reduce()` only when the cross-option condition is false
([baseline patch, override body](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/solutions/solution_baseline.patch#L9)).
The unmet obligation is parent preservation: if `super().reduce()` would return a
non-`False` result (an elidable reduction, a same-option replacement list) for
the same pair that also satisfies the cross-option condition, baseline's early
`True` shadows it. The intent records that the override must preserve inherited
non-`False` reductions *before* adding the new case
([`fvk/SPEC.md` INT-7](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/SPEC.md#L30)).

## 3. How FVK formally captured the gap

FVK started from the inherited operation contract, not just the reported symptom,
and wrote the parent-preservation requirement into the intent ledger:

> **INT-7.** *`Operation.reduce()` handles elidable operations generically.* →
> *"The override must preserve inherited non-false reductions before adding the
> new cross-option case."*
> — [`fvk/SPEC.md` INT-7](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/SPEC.md#L30)

That intent is pinned to a concrete code fact found by source audit — what
`state_forwards()` and the schema editor actually do — not to the reported issue
sequence:

> **INT-8 (schema/state implementation evidence).** *"`state_forwards()` alters
> only `{self.option_name: self.option_value}`; schema editor has separate
> `alter_unique_together()` and `alter_index_together()` methods."* → *"Unique-
> together and index-together are independent frame dimensions for this
> reduction."*
> — [`fvk/SPEC.md` INT-8](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/SPEC.md#L31)

The parent-preservation question is then discharged into a dedicated obligation
the reported sequence cannot see:

> **PO-1: Parent Preservation.** *`parent(self, op) != False => reduceAT(self, op)
> == parent(self, op)`* — *"This preserves inherited elidable, same-option,
> delete, and different-model pass-through reductions."*
> — [`fvk/PROOF_OBLIGATIONS.md` PO-1](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/PROOF_OBLIGATIONS.md#L22)

This is the gap located by reasoning: the issue and its example only ask that the
split sequence collapse (covered by
[PO-2](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/PROOF_OBLIGATIONS.md#L32)
/ [PO-4](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/PROOF_OBLIGATIONS.md#L54)),
but the formal contract additionally states the new override must never override
an inherited non-`False` result — a property no test in the suite checks, and
exactly the one baseline's early `return True` can violate.

## 4. From formal output to the fix

The audit raised one robustness finding against V1 (baseline), tied to its
obligation and then to a concrete V2 edit.

- Finding — V1 short-circuited before consulting the parent reducer:

  > **F-001: V1 bypassed inherited non-false reductions.** *"Observed in V1: the
  > override checked the cross together-option case first and returned `True`. …
  > Resolution: fixed in V2 by assigning `result = super().reduce(operation,
  > app_label)`, returning it when `result is not False`, and only then applying
  > the cross-option transparency rule."*
  > — [`fvk/FINDINGS.md` F-001](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L5)

- The core legacy fix (the cross-option `True`) is confirmed correct and kept:

  > **F-002: Original optimizer could not collapse split together-option
  > remove/add operations.** *"Resolution: fixed by PO-2 and PO-4. Different
  > together options on the same model return `True` after inherited reductions
  > fail."*
  > — [`fvk/FINDINGS.md` F-002](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L15)

- Iteration guidance turned F-001 into the single V2 refinement:

  > *"F-001 showed that the override should preserve inherited reducer results
  > before applying the new cross-option transparency rule. V2 makes that
  > refinement … F-001 / PO-1: preserve inherited non-`False` behavior. F-002 /
  > PO-2 / PO-4: enable the issue's split remove/add sequence to collapse."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/ITERATION_GUIDANCE.md#L7)

- The decision trace records the resulting edit and its provenance:

  > *"I revised V1 instead of leaving it unchanged because … F-001 showed a
  > parent-preservation gap: V1 returned `True` for cross `AlterUniqueTogether`/
  > `AlterIndexTogether` operations before consulting inherited reducer behavior.
  > … PO-1 requires inherited non-`False` reductions to win. V2 now stores
  > `result = super().reduce(operation, app_label)` and returns it whenever
  > `result is not False`."*
  > — [`reports/fvk_notes.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/reports/fvk_notes.md#L5)

The causal chain:

```
SPEC INT-7 / INT-8  ->  PO-1 (preserve inherited non-False reductions)
                    ->  F-001 (V1 returns True before consulting super().reduce())
                    ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The V2 patch
([`solutions/solution_fvk.patch`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/solutions/solution_fvk.patch))
keeps the same cross-option rule but reorders the override so the parent reducer
runs first — assigning `result = super().reduce(...)`, returning it when
`result is not False`, and only then applying the cross-option `True` (with a
final explicit `return False`)
([fvk patch, reordered override](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/solutions/solution_fvk.patch#L9)).
The two patches differ only in that reordering: baseline does the cross-option
check then `return super().reduce(...)` as a fallthrough (8 added lines); FVK
calls `super().reduce(...)` first, then the cross-option check, then
`return False` (11 added lines). The `V1 -> V2` transition was driven entirely by
the formal finding F-001 and obligation PO-1 — **not** by any new test; the run
had no execution environment and added no tests
([`fvk/FINDINGS.md` F-004](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L34)).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** The run forbade running
tests, Python, or K tooling
([`prompts/fvk.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/prompts/fvk.md#L27)),
so there is no harness RED/GREEN and no executed behavioral demonstration. What
was inspected, and supports the conclusions above:

- The two patches were diffed against each other and against the issue. Both add
  the identical cross-option transparency rule (`isinstance(..., AlterTogether
  OptionOperation)` + same `name_lower` + different `option_name` → `True`); they
  differ only in *order* — baseline checks the rule first and falls through to
  `super().reduce()`, FVK calls `super().reduce()` first and only applies the rule
  when the parent result is `False`. Both therefore collapse the reported split
  sequence; FVK additionally cannot shadow an inherited non-`False` reduction
  ([baseline](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/solutions/solution_baseline.patch#L9),
  [fvk](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/solutions/solution_fvk.patch#L9)).

- The constructed proof traces the optimizer's fixed-point loop over the issue's
  four-operation example down to the two final operations by symbolic execution
  of the reordered override, and checks that field-operation boundaries remain
  boundaries because the new `True` branch fires only for another
  `AlterTogetherOptionOperation`
  ([`fvk/PROOF.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/PROOF.md#L47),
  [`fvk/FINDINGS.md` F-003](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L25)).

**Comparison to the human oracle.** The official gold fix scopes the new
reduction to the `AlterUniqueTogether` / `AlterIndexTogether` family and resolves
the reported optimizer failure, the same behavior FVK's V2 achieves. FVK
re-derived the parent-first ordering from the PO-1 preservation obligation rather
than from the reference solution. (No gold artifact is attached to this
non-curated run, so this is a prose comparison only.)

## 6. Boundaries & honesty

- **Severity: Low.** The trigger breadth is narrow. Baseline's residual cannot
  produce a wrong migration for the reported case — the split sequence collapses
  correctly in both arms — and it does not touch runtime database correctness. It
  bites only the optimizer-composition path where, for the *same* operation pair,
  `super().reduce()` would return a non-`False` result (an elidable reduction or a
  same-option replacement list) that *also* satisfies the cross together-option
  condition; baseline's early `return True` then drops that inherited reduction.
  This is a migration-optimizer simplification edge, not user data corruption,
  which places it at Low per the rubric
  ([`fvk/FINDINGS.md` F-001](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L5)).

- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-migration-optimizer.k`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/mini-migration-optimizer.k),
  [`alter-together-reduce-spec.k`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/alter-together-reduce-spec.k))
  and the `kompile`/`kast`/`kprove` commands were written but never run; the run
  artifacts state this explicitly
  ([`fvk/PROOF.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/PROOF.md#L3),
  [`fvk/FINDINGS.md` F-004](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L34)).
  The claim is proof-*structured* reasoning — a contract whose obligations (PO-1,
  PO-2, PO-4) are discharged by construction — not a machine-checked proof.

- **Attribution.** The existing doc's framing ("baseline returns `True` before
  consulting inherited reducer behavior; FVK preserves the parent reducer result
  before applying the together-option pass-through rule") is confirmed by the
  actual patches: the only delta between the two arms is the reordering of the
  `super().reduce()` call relative to the cross-option check. The old doc's
  references to "F-001/PO-1 inherited non-`False` reductions must win" and
  "F-002/PO-2/PO-4 cross together-option transparency" map correctly onto the
  artifacts — F-001/PO-1 is the parent-preservation residual, F-002/PO-2/PO-4 is
  the legacy collapse the override enables — and are linked precisely above. (The
  old doc cited "PO-2/PO-4"; the proof obligation file confirms PO-2 is the
  transparency rule and PO-4 the exact-sequence reduction.) No machine-checked
  verdict and no executed demonstration exist for this instance; the conclusions
  rest on patch and source review.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, example sequence | [`prompts/fvk.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/prompts/fvk.md#L2), [`fvk/SPEC.md` INT-1/INT-4](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/SPEC.md#L24) |
| Root cause (cross-class boundary) | [`reports/baseline_notes.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/reports/baseline_notes.md#L5), [`fvk/FINDINGS.md` F-002](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L15) |
| Baseline patch (rule-first override) | [`solutions/solution_baseline.patch`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/solutions/solution_baseline.patch#L9) |
| Baseline reasoning (scope, rejected broadening) | [`reports/baseline_notes.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/reports/baseline_notes.md#L19) |
| FVK patch (parent-first override) | [`solutions/solution_fvk.patch`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/solutions/solution_fvk.patch#L9) |
| Intent INT-7 (preserve inherited reductions) | [`fvk/SPEC.md` INT-7](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/SPEC.md#L30) |
| Evidence INT-8 (frame independence, code audit) | [`fvk/SPEC.md` INT-8](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/SPEC.md#L31) |
| Obligation PO-1 (parent preservation) | [`fvk/PROOF_OBLIGATIONS.md` PO-1](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/PROOF_OBLIGATIONS.md#L22) |
| Obligation PO-2 (cross-option transparency) | [`fvk/PROOF_OBLIGATIONS.md` PO-2](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/PROOF_OBLIGATIONS.md#L32) |
| Obligation PO-4 (exact-sequence reduction) | [`fvk/PROOF_OBLIGATIONS.md` PO-4](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/PROOF_OBLIGATIONS.md#L54) |
| Finding F-001 (rule-first vs parent-first) | [`fvk/FINDINGS.md` F-001](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L5) |
| Finding F-002 (original collapse failure) | [`fvk/FINDINGS.md` F-002](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L15) |
| Finding F-003 (field boundaries preserved) | [`fvk/FINDINGS.md` F-003](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L25) |
| Iteration guidance (V1→V2 refinement) | [`fvk/ITERATION_GUIDANCE.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (provenance of edit) | [`reports/fvk_notes.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/reports/fvk_notes.md#L5) |
| Constructed optimizer proof trace | [`fvk/PROOF.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/PROOF.md#L47) |
| Honesty boundary (no execution) | [`fvk/FINDINGS.md` F-004](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/FINDINGS.md#L34) |
| Proof status / kprove not run | [`fvk/PROOF.md`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/PROOF.md#L3) |
| Constructed K core | [`fvk/mini-migration-optimizer.k`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/mini-migration-optimizer.k), [`fvk/alter-together-reduce-spec.k`](../results/verified019-codex-XC-MINI-PRO-AHP-20260616T072953Z/django__django-15268/fvk/alter-together-reduce-spec.k) |
