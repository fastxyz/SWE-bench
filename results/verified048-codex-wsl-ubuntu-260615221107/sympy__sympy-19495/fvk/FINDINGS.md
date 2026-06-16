# FVK Findings

Status: constructed, not machine-checked.

## F1: Resolved Code Bug - External True Guard Used Replacement as Dummy

Input: `ConditionSet(x, Contains(y, Interval(-1, 1)),
imageset(Lambda(n, 2*n*pi + asin(y)), S.Integers)).subs(y, Rational(1, 3))`

Observed before V1: a malformed `ConditionSet` whose dummy was `1/3` and whose
condition checked membership of `1/3` in the substituted `ImageSet`.

Expected: the substituted `ImageSet`, matching the issue's `xreplace`,
`simultaneous=True`, and plain `ImageSet.subs` examples.

Root cause: the true-condition branch in `ConditionSet._eval_subs` always
returned `ConditionSet(new, Contains(new, base), base)`, even when the true
condition was an external parameter guard independent of the dummy.

Resolution: V1 satisfies PO1 and PO2 by returning the substituted base when the
original condition is independent of the dummy.

## F2: Rejected Over-Correction - Do Not Return Base for Every True Condition

Input class: `ConditionSet(n, n < x, Interval(...)).subs(x, p)` where `n` has
assumptions and the substituted condition becomes true because of those
assumptions.

Risk: replacing the entire `cond is S.true` branch with `return base` would also
change dummy-dependent assumption behavior covered by public in-repo tests.

Resolution: V1 satisfies PO3 by applying `return base` only when the original
condition is dummy-independent.

## F3: Proof Capability Gap - Full SymPy Semantics Not Modeled

Input class: arbitrary SymPy substitutions involving assumptions, binders,
`Contains`, `ImageSet.contains`, and constructor simplification.

Observed limitation: the FVK fast path does not provide a full Python/SymPy K
semantics for these features.

Expected handling: the abstract K model must prove only the branch decision it
can faithfully represent and must not claim full SymPy verification.

Resolution: PO7 records the adequacy of the abstraction for the reported return
shape; PO8 keeps the proof labeled constructed, not machine-checked. This is not
a source-code bug in V1.

## F4: No Compatibility Finding

Input class: callers using `Basic._subs` to invoke `ConditionSet._eval_subs`.

Observed: V1 does not change the signature, dispatch protocol, or test files.

Expected: public compatibility is preserved.

Resolution: PO5 and PO6 are discharged.

## Proof-Derived Findings from `/verify`

No additional source-code defect was derived. The proof construction confirms
that V1 is the minimal branch split needed to satisfy PO1/PO2 while preserving
PO3/PO4. The only open item is PO8: the K artifacts were not machine-checked
because this environment forbids running K tooling.

