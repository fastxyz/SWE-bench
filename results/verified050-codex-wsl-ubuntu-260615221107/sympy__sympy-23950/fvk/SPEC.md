# FVK Specification for sympy__sympy-23950

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

Audited units:

- `sympy.logic.boolalg.Boolean.as_set`
- `sympy.logic.boolalg.Boolean._eval_as_set` as added by V1
- `sympy.sets.contains.Contains.as_set` as changed by V1
- The existing `sympy.sets.conditionset.ConditionSet.__new__` normalization path that V1 relies on

Out of scope for this proof: complete SymPy object construction semantics, solver completeness for relationals, multivariate Boolean set conversion, and total correctness/performance. Those are existing broader library concerns and are not needed to discharge the public issue intent.

## Intent Spec

I1. `Contains(x, Reals).as_set()` must return a Set, not a Boolean `Contains`.

Evidence: `benchmark/PROBLEM.md` says "`Contains.as_set` returns `Contains`" and "This is wrong because `Contains` is not a set (it's a boolean)."

I2. A Boolean's `as_set()` represents the set `{x | p}` when the Boolean has one free variable.

Evidence: public hint says "`p.as_set()` for a boolean `p` ... should return a set representing `{x | p}`, where `x` is the free variable in `p`."

I3. For a symbol-membership condition, `Contains(x, set).as_set()` should return the member set.

Evidence: public hint says "if `x` is a symbol, `Contains(x, set).as_set()` should just return `set`."

I4. A false Boolean/membership condition must produce `EmptySet`, not a non-Set expression.

Evidence: public hint says "unless contains is False in which case EmptySet should be returned" and rejects literal `Piecewise` because "`Piecewise` doesn't have any of the methods of Set."

I5. Existing public callers that use `cond.as_set()` must receive an object with Set behavior, including `as_relational` where applicable.

Evidence: problem traceback states other code fails because `Contains` "doesn't have `as_relational` (since it isn't a set)."

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`Contains(x, Reals).as_set()` returns `Contains(x, Reals)`" is wrong | `Contains.as_set` must not return a Boolean for symbolic membership | encoded by O1/O2 |
| E2 | prompt | Boolean `p.as_set()` should return `{x | p}` for one free variable | generic fallback to `ConditionSet(x, p)` | encoded by O3 |
| E3 | prompt | "`Contains(x, set).as_set()` should just return `set`" | symbol membership normalizes to the member set | encoded by O1/O2 |
| E4 | prompt | false Boolean should give `EmptySet`; do not return `Piecewise` | false condition reaches Set semantics | encoded by O4 |
| E5 | code | `ConditionSet.__new__` returns `condition.args[1].intersect(base_set)` for `ConditionSet(sym, Contains(sym, set), base_set)` | V1 may rely on `ConditionSet` for normalization | encoded by O2 |
| E6 | public-test | `repo/sympy/sets/tests/test_contains.py::test_as_set` expects `NotImplementedError` for `Contains(x, FiniteSet(y)).as_set()` | SUSPECT legacy test: conflicts with E2/E3 and should not constrain the fix | finding F2 |

## Formal Spec English

FSE1. For every symbolic `X` and Set `S`, `Contains(X, S).as_set()` reaches the Set `S`, using `ConditionSet(X, Contains(X, S))` followed by `ConditionSet` membership flattening and `UniversalSet` intersection identity.

FSE2. For `S = EmptySet`, `Contains(X, EmptySet).as_set()` reaches `EmptySet`.

FSE3. For any Boolean `P` with exactly one free symbol `X` and no more specific set conversion, `P.as_set()` reaches `ConditionSet(X, P)`.

FSE4. For a Boolean with more than one free symbol, the existing `NotImplementedError` boundary remains. The public hint explicitly says multivariate behavior is not implemented and is uncertain.

FSE5. No changed public method signature, argument shape, or return protocol is introduced; only the return value of `Contains.as_set()` on in-domain symbolic membership changes from unimplemented/Boolean behavior to a Set.

## Spec Audit

| Formal English | Intent match | Notes |
| --- | --- | --- |
| FSE1 | pass | Directly implements I1 and I3. |
| FSE2 | pass | Directly implements I4 through existing `ConditionSet` and `EmptySet` behavior. |
| FSE3 | pass | Directly implements I2 for one-free-variable Booleans not already handled by a subclass. |
| FSE4 | pass | The issue itself says multivariate conversion is not implemented and unclear. |
| FSE5 | pass | Compatibility audit found no signature or dispatch-shape change. |

## Public Compatibility Audit

Changed public behavior:

- `Contains.as_set()` no longer raises/returns non-Set behavior for symbolic membership; it returns a Set.
- `Boolean._eval_as_set()` adds an internal fallback used by `Boolean.as_set()`.

Callsite compatibility:

- Public callers of `cond.as_set()` expect a Set. Returning a Set improves compatibility with `as_relational` consumers.
- No callsites pass new parameters or rely on a changed signature.
- Existing stale public test `test_contains.py::test_as_set` is marked SUSPECT because it enshrines the unsupported behavior the issue asks to fix.

## K Artifact Map

The mini semantics and claims are written in:

- `fvk/mini-sympy-as-set.k`
- `fvk/contains-as-set-spec.k`

They are intentionally narrow: they model only the observable branch structure needed for the audited obligations above.
