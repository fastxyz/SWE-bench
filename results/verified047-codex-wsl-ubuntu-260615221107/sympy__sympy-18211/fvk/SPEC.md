# FVK Specification: relational `as_set` fallback

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Scope

Target unit: `repo/sympy/core/relational.py`,
`Relational._eval_as_set`.

The audited path is the univariate real-set conversion path reached from
`Boolean.as_set()` after the existing free-symbol and periodicity checks. This
matches the method comment: `self is univariate and periodicity(self, x) in
(0, None)`.

Out of scope for this proof:

- multivariate `as_set`, which is rejected by `Boolean.as_set` before this
  method is used;
- nontrivial periodic relationals, which `Boolean.as_set` already handles
  separately;
- direct callers of `solve_univariate_inequality`, whose documented API still
  permits `NotImplementedError`;
- termination and performance.

## Intent Spec

I1. For a univariate relational whose solution set can be determined by
`solve_univariate_inequality(..., relational=False)`, `as_set()` must return
that solved set unchanged.

I2. For a univariate relational in the real `as_set()` domain where
`solve_univariate_inequality(..., relational=False)` raises
`NotImplementedError` because the relation is not solvable by that routine,
`as_set()` must not propagate that exception. It must return
`ConditionSet(x, relation, S.Reals)`.

I3. The condition in the returned `ConditionSet` must preserve the original
relational predicate, and the base set must be `S.Reals`.

I4. The fix must not change the public signature of `_eval_as_set`,
`as_set()`, or `solve_univariate_inequality`, and must not change solved-case
results.

## Public Evidence Ledger

E1. Source: prompt. Quote: "`Eq(n*cos(n) - 3*sin(n), 0).as_set()` ...
`NotImplementedError`". Obligation: this exception is the symptom and must not
escape for the reported in-domain expression. Status: encoded by I2 and claim
`(AS-SET-NOTIMPLEMENTED)`.

E2. Source: prompt. Quote: "probably a `ConditionSet` should be returned" and
"The obvious result ... `ConditionSet(n, Eq(n*cos(n) - 3*sin(n), 0), Reals)`".
Obligation: fallback result shape is a `ConditionSet` over `Reals`, with the
original equation as the condition. Status: encoded by I2, I3, and claim
`(AS-SET-NOTIMPLEMENTED)`.

E3. Source: public hint. Quote: "solve_univariate_inequality raises
NotImplementedError for unsolvable equations/inequalities." Obligation: the
fallback trigger is specifically solver incompleteness represented by
`NotImplementedError`. Status: encoded by I2 and proof obligation PO3.

E4. Source: public tests. Quote: `Eq(x, 0).as_set() == FiniteSet(0)` and
interval assertions for `x > 0`, `x >= 0`, `x < 0`, `x <= 0`, `x**2 >= 4`.
Obligation: solved univariate relationals keep returning solver-produced sets.
Status: encoded by I1 and claim `(AS-SET-SOLVED)`.

E5. Source: implementation convention. `Boolean.as_set()` rewrites Boolean
expressions "in terms of real sets" and `Not` complements relative to
`S.Reals`; `solve_univariate_inequality` defaults to `domain=S.Reals`.
Obligation: the fallback base set is `S.Reals`. Status: encoded by I3.

E6. Source: existing `solveset` implementation. For a relational in a real
domain, `solveset` catches `NotImplementedError` from
`solve_univariate_inequality` and returns `ConditionSet(symbol, f, domain)`.
Obligation: the relational `as_set` path should follow the same unsolved
relation convention. Status: supporting evidence for I2 and I3.

## Formal Spec English

Claim `(AS-SET-SOLVED)`: For any univariate relation `R` with free symbol `X`,
if the underlying solver returns a set `S`, evaluating relational `as_set` for
`R` returns `S` and leaves no `NotImplementedError` exception.

Claim `(AS-SET-NOTIMPLEMENTED)`: For any univariate relation `R` represented as
`rel(X)`, if the underlying solver reports incompleteness with
`NotImplementedError`, evaluating relational `as_set` returns
`conditionSet(X, rel(X), Reals)` and leaves no `NotImplementedError`
exception.

There are no loop circularities and no recursive calls in the modeled change.

## Adequacy Audit

I1 vs `(AS-SET-SOLVED)`: pass. The claim is exactly the solved-case frame
condition required by public tests and the existing delegation design.

I2 vs `(AS-SET-NOTIMPLEMENTED)`: pass. The claim converts the solver
incompleteness branch into a `ConditionSet` instead of an exception.

I3 vs `(AS-SET-NOTIMPLEMENTED)`: pass. The claim preserves the symbolic
relation and uses `Reals` as the base domain.

I4 vs both claims: pass. The claims do not change direct solver behavior or any
public signature; they only specify the wrapper method's two observable
branches.

Ambiguity check: the prompt says "`solveset` raises" but the reproduction is
`Eq(...).as_set()`. The audited production change is still adequate because the
observed public API path is relational `as_set`, and the existing `solveset`
relational branch already has this `ConditionSet` behavior.

## Public Compatibility Audit

Changed public symbol: `Relational._eval_as_set`, a protected method used by
`Boolean.as_set()` for relational conversion.

Signature compatibility: unchanged.

Return-type compatibility: solved cases remain whatever set
`solve_univariate_inequality(..., relational=False)` returns. Previously
unhandled `NotImplementedError` cases now return a `ConditionSet`, which is a
`Set`, matching the method's purpose.

Exception compatibility: only `NotImplementedError` from solver
incompleteness is intercepted. Other exceptions and the existing univariate
assertion are not broadened.

Public callsites reviewed: `Boolean.as_set()` and existing univariate
relational tests. No caller or subclass override requires an update.

## Formal Artifacts

The FVK formal core is present as:

- `fvk/mini-sympy-as-set.k`
- `fvk/relational-as-set-spec.k`

Commands to run later in an environment with K installed:

```sh
cd fvk
kompile mini-sympy-as-set.k --backend haskell
kast --backend haskell relational-as-set-spec.k
kprove relational-as-set-spec.k
```

Expected result after machine checking: `kprove` returns `#Top`.
