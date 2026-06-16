# Proof Obligations

Status: constructed, not machine-checked.

## PO1: External True Guard Collapses to Base

Obligation: If `old != sym`, `condition.subs(old, new) is S.true`, and
`condition` is independent of `sym` under `sym.free_symbols`, then
`ConditionSet._eval_subs` returns `base.subs(old, new)`.

Evidence: I1, I2, E1, E2, E4.

Status: discharged by the V1 branch at
`repo/sympy/sets/conditionset.py:245-249` and by claim 1 in
`conditionset-subs-spec.k`.

## PO2: ImageSet Base Shape Is Preserved

Obligation: In PO1, if `base.subs(old, new)` is an `ImageSet`, the result is that
`ImageSet`, not a `ConditionSet` with `new` as dummy.

Evidence: I2, I3, E2, E3.

Status: discharged as a corollary of PO1. The V1 branch returns `base` directly
after computing `base = self.base_set.subs(old, new)`.

## PO3: Dummy-Dependent True Guard Keeps Legacy Fallback

Obligation: If `old != sym`, `condition.subs(old, new) is S.true`, and
`condition` depends on `sym`, V1 must keep the existing fallback
`ConditionSet(new, Contains(new, base), base)`.

Evidence: I4 and E5.

Status: discharged by `repo/sympy/sets/conditionset.py:248-250` and by claim 2
in `conditionset-subs-spec.k`.

## PO4: Non-True Guard Frame

Obligation: If `old != sym` and `condition.subs(old, new)` is not `S.true`, V1
must preserve the existing constructor-mediated result
`self.func(self.sym, cond, base)`.

Evidence: I5 and E6.

Status: discharged because V1 does not edit this branch; claim 3 in
`conditionset-subs-spec.k` records the frame.

## PO5: Existing `old == sym` Behavior Is Framed

Obligation: V1 must not change the special branch that handles direct attempts to
substitute the `ConditionSet` dummy.

Evidence: I5 and public tests in `test_subs_CondSet`.

Status: discharged by source diff inspection: V1 changed only lines 245-249 in
the `old != sym` branch.

## PO6: API Compatibility

Obligation: V1 must not change `_eval_subs` signature, dispatch protocol, or test
files.

Evidence: I5 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged.

## PO7: Adequacy of the Abstract Model

Obligation: The K model must distinguish the reported failing return shape from
the intended substituted-base return shape.

Evidence: E1 and E2.

Status: discharged for the audited branch. `SetObj` has separate constructors
for `ImageSetObj`, `ConditionSetObj`, and `ConditionSetValueObj`.

## PO8: Machine Check Deferred

Obligation: Do not claim machine-checked proof or delete tests until the emitted
K commands are run and return `#Top`.

Evidence: FVK honesty gate and user instruction not to run K tooling.

Status: open operational step, not a code bug.

