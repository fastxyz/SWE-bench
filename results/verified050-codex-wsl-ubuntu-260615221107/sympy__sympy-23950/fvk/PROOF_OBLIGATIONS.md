# Proof Obligations

Status: constructed, not machine-checked.

## O1 - Symbolic Contains enters the Set-producing branch

Claim: for an unevaluated `Contains(X, S)` where `X.is_Symbol` and `S` is a Set, `Contains.as_set()` does not raise `NotImplementedError` and does not return `Contains`.

Code evidence: `repo/sympy/sets/contains.py` checks `if self.args[0].is_Symbol` and returns `ConditionSet(self.args[0], self)`.

Public evidence: E1 and E3 in `fvk/SPEC.md`.

Status: discharged by source inspection and K claim `CONTAINS-AS-SET-SYMBOL`.

## O2 - ConditionSet flattens symbolic membership to the member set

Claim: `ConditionSet(X, Contains(X, S), UniversalSet)` returns `S`.

Code evidence: `ConditionSet.__new__` checks `isinstance(condition, Contains) and (sym == condition.args[0])`, then returns `condition.args[1].intersect(base_set)`. `UniversalSet` is the intersection identity for Sets.

Public evidence: E3 and E4.

Status: discharged by source inspection and K claim `CONDITIONSET-CONTAINS-FLATTEN`.

## O3 - Generic one-free-symbol Boolean fallback returns ConditionSet

Claim: for a Boolean `P` with exactly one free symbol `X`, when no subclass-specific `_eval_as_set` handles it, `Boolean.as_set()` can reach `Boolean._eval_as_set()` and return `ConditionSet(X, P)`.

Code evidence: V1 adds `Boolean._eval_as_set()` with `if len(free) == 1: return ConditionSet(free.pop(), self)`.

Public evidence: E2.

Status: discharged by source inspection and K claim `BOOLEAN-EVAL-AS-SET-ONE-FREE`.

## O4 - False membership produces EmptySet, not Piecewise

Claim: a false membership condition reaches `EmptySet`.

Code evidence: normal `Contains` construction returns `S.false` for false membership, and `BooleanFalse.as_set()` returns `S.EmptySet`; for unevaluated symbolic membership over `EmptySet`, `ConditionSet` flattening returns `EmptySet.intersect(UniversalSet)`, which is `EmptySet`.

Public evidence: E4.

Status: discharged by source inspection and K claim `CONTAINS-AS-SET-EMPTY`.

## O5 - Callers receive Set behavior

Claim: the output of `Contains(x, set).as_set()` is a Set with Set methods rather than a Boolean `Contains`.

Code evidence: `ConditionSet` flattening returns `condition.args[1].intersect(base_set)`, whose result is a Set.

Public evidence: E1 and E5.

Status: discharged for the audited membership family. Broader Set method correctness is inherited from existing SymPy Set classes and is outside this patch.

## O6 - Multivariate boundary is preserved

Claim: Booleans with more than one free symbol may still raise `NotImplementedError`.

Code evidence: `Boolean.as_set()` still raises for `len(free) != 1`.

Public evidence: the issue hint says multivariate behavior "isn't implemented yet" and the author is not sure what it would do.

Status: discharged as an intentional precondition/boundary, not a bug.

## O7 - No execution-based claims

Claim: this FVK run must not depend on test, Python, or K execution.

Code/evidence: all conclusions come from public issue text and source inspection. Commands are listed in `fvk/PROOF.md` but not run.

Status: discharged.
