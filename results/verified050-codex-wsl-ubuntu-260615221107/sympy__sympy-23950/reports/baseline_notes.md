Root cause:

`Contains` is a BooleanFunction, but `Contains.as_set()` raised `NotImplementedError` instead of returning a Set. Code such as `Piecewise` calls `cond.as_set().as_relational(x)` for Boolean conditions, so a membership condition could not be converted into a usable set. More generally, `Boolean.as_set()` assumed every one-variable Boolean subclass supplied `_eval_as_set()`, leaving unsupported BooleanFunction subclasses without a safe fallback.

Changed files:

`repo/sympy/logic/boolalg.py`

Added a default `Boolean._eval_as_set()` implementation. For a Boolean with exactly one free symbol, it now returns `ConditionSet(symbol, boolean)`. This matches the set-builder interpretation of `p.as_set()` and lets `ConditionSet` perform its existing simplifications, including reduction to `EmptySet` for false conditions.

`repo/sympy/sets/contains.py`

Changed `Contains.as_set()` so `Contains(x, set)` with symbolic `x` returns `ConditionSet(x, Contains(x, set))`. The existing `ConditionSet` constructor immediately normalizes this membership condition to the represented set intersected with the base set, so `Contains(x, S.Reals).as_set()` becomes `S.Reals` rather than a Boolean. Non-symbol membership expressions fall back to the generic Boolean conversion.

Assumptions and rejected alternatives:

I treated the left-hand symbol in `Contains(x, set)` as the bound variable for the resulting set, while symbols appearing inside `set` are parameters. This follows the public issue hint that `Contains(x, set).as_set()` should return `set`. I rejected returning a `Piecewise` expression for true/false membership because the caller expects Set methods such as `as_relational`. I also rejected hard-coding `Contains.as_set()` to return `self.args[1]` directly because routing through `ConditionSet` preserves existing normalization for empty, false, and nested condition-set cases.
