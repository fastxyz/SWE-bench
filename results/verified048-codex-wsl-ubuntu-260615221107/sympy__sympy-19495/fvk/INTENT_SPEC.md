# Intent Specification

Status: constructed from public evidence, not machine-checked.

## Target

The audited unit is `ConditionSet._eval_subs` in `repo/sympy/sets/conditionset.py`,
restricted to substitution through a `ConditionSet` with an expression dummy
symbol. The V1 edit changed only the branch where `old != self.sym` and the
substituted condition evaluates to `S.true`.

## Intent Obligations

I1. A `ConditionSet(sym, condition, base)` denotes elements of `base` satisfying
`condition` with respect to the bound dummy `sym`. If `condition` is independent
of `sym` and substitution of an external parameter makes `condition` true, the
result is the substituted `base`.

I2. Substitution of an external parameter must not reuse the replacement value as
the `ConditionSet` dummy. In the issue example, substituting `y = Rational(1, 3)`
must not produce a `ConditionSet` whose dummy is `1/3`.

I3. Substitution must still recurse into the base set. In particular, when the
base is `ImageSet(Lambda(n, 2*n*pi + asin(y)), S.Integers)`, substituting
`y = Rational(1, 3)` inside the surrounding `ConditionSet` must preserve the
same `ImageSet` substitution behavior that works for the plain `ImageSet`.

I4. Existing dummy-dependent behavior is preserved: when the original condition
depends on the `ConditionSet` dummy and becomes true because of assumptions, the
legacy fallback `ConditionSet(new, Contains(new, base), base)` remains the
intended compatibility behavior unless public intent says otherwise.

I5. Public API compatibility is preserved: no signature change to
`ConditionSet._eval_subs`, no test-file edits, and no change to the general
`Basic._subs` dispatch protocol.

