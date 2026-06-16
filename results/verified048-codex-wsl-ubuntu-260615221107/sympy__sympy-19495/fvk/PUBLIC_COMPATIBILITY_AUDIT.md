# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbol

`ConditionSet._eval_subs(self, old, new)`

Compatibility result: pass.

The method signature is unchanged. The method remains an override of SymPy's
internal `_eval_subs` protocol and is still called by `Basic._subs` with the same
arguments. The V1 edit changes only one return branch after local substitution
has already produced `cond` and `base`.

## Return Shape

Compatibility result: pass.

Returning a `Set` that is not a `ConditionSet` is already part of
`ConditionSet` construction semantics: `ConditionSet.__new__` returns the base
set when the condition is `S.true`, and returns `S.EmptySet` when the condition is
`S.false`. Returning the substituted base for a true dummy-independent guard is
therefore compatible with the class' public construction behavior.

## Public Callers and Overrides

Compatibility result: pass.

No new parameters, keyword arguments, virtual dispatch calls, or storage formats
were introduced. No test files were changed.

