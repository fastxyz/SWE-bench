# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F1: Pre-V1 `OuterRef` Scope Bug Is Real And Localized

- Classification: code bug, addressed by V1.
- Related obligations: PO1, PO2.
- Input: `Number.objects.filter(Exists(Item.objects.exclude(tags__category_id=OuterRef('pk'))))` and the analogous `filter(~Q(...))` form.
- Observed before V1: the public hint reports `OuterRef` resolving to the immediate `Item` alias, e.g. `"V0"."id"`.
- Expected: `OuterRef('pk')` resolves to the enclosing `Number` query's primary key.
- Cause: `split_exclude()` adds a generated nested query. Treating an existing `OuterRef('pk')` like a plain `F('pk')` gives it only one `OuterRef` wrapper, so it is consumed one resolution pass too early.
- V1 status: V1 wraps an existing `OuterRef` as `OuterRef(filter_rhs)`, which adds the required extra level.

## F2: V1 Preserves Plain `F()` Behavior

- Classification: compatibility confirmation.
- Related obligation: PO3.
- Input: negated many-valued relation lookup whose RHS is a plain `F()` expression.
- Expected: the local `F()` reference is shifted outward once to the immediate parent query.
- V1 status: the existing `elif isinstance(filter_rhs, F)` branch is unchanged, and the formal claim reduces to `Bound(1, "local_field")`.

## F3: V1 Does Not Change Non-Expression RHS Handling

- Classification: compatibility confirmation.
- Related obligation: PO4.
- Input: negated many-valued relation lookup whose RHS is neither `OuterRef` nor `F`.
- Expected: no scope-shifting rewrite is applied.
- V1 status: the formal claim keeps `Literal("rhs")` unchanged.

## F4: No Additional Source Change Is Justified By The FVK Audit

- Classification: repair decision.
- Related obligations: PO1 through PO5.
- Decision: keep V1 unchanged.
- Rationale: the proof obligations identify exactly one defect in V0 and the V1 source edit discharges it while preserving compatibility obligations. No finding requires edits to `Query.resolve_expression()`, `OuterRef.resolve_expression()`, lookup resolution, or public APIs.

## F5: Escalation Boundary - Full ORM SQL Generation Is Not Proved

- Classification: proof capability boundary, not a discovered code bug.
- Related obligation: PO6.
- Scope not proved: complete SQL rendering, join trimming, null semantics, database execution, and planner behavior.
- Reason this is acceptable for this pass: the public issue and hint localize the defect to reference binding level, and the mini semantics preserves that observable distinction between `Item` binding and `Number` binding.

## F6: Verification And Test Removal Are Conditional

- Classification: honesty gate.
- Related artifact: `PROOF.md`.
- Status: `kompile`, `kast`, and `kprove` commands are emitted but were not executed. No test removal is recommended before machine-checking and normal test execution in a suitable environment.

