# Baseline Notes

## Root Cause

`ConditionSet._eval_subs` has special handling for substitutions that make the
condition evaluate to `S.true`. It rebuilt the result as
`ConditionSet(new, Contains(new, base), base)` unconditionally.

That behavior is only appropriate for the existing assumption-sensitive case
where the original condition depends on the `ConditionSet` dummy symbol. In the
reported case, the condition is an external parameter guard,
`Contains(y, Interval(-1, 1))`, and does not depend on the bound symbol `x`.
After substituting `y = 1/3`, the guard becomes true, so the result should be the
substituted base `ImageSet`. Instead, the replacement value `1/3` was used as the
new dummy argument of the `ConditionSet`, producing the malformed set shown in
the issue.

## Changed Files

`repo/sympy/sets/conditionset.py`

Added a dependency check in `ConditionSet._eval_subs` before applying the
existing `ConditionSet(new, Contains(new, base), base)` fallback. If the original
condition did not depend on the `ConditionSet` dummy, and the substituted
condition evaluates to true, substitution now returns the substituted base set
directly. This preserves the intended result for external parameter guards such
as `Contains(y, Interval(-1, 1))` while leaving the prior fallback in place for
conditions whose truth depends on assumptions attached to the dummy symbol.

## Assumptions and Alternatives Considered

I assumed that a condition independent of the bound symbol acts as a guard on the
entire base set. Once that guard becomes true under substitution, the correct
result is the base set with the same substitution applied.

I considered replacing the `cond is S.true` branch with `return base` in all
cases. I rejected that because the existing code and tests cover cases where the
condition can become true due to assumptions on the bound symbol; those cases use
the current `ConditionSet(new, Contains(new, base), base)` behavior to account
for membership of the substituted value in the base.

I also considered changing `ImageSet` substitution or `Contains` evaluation, but
plain substitution on `ImageSet` is already described as working correctly in the
issue. The incorrect dummy/value mix-up happens in `ConditionSet._eval_subs`
after both the condition and base set have already been substituted.
