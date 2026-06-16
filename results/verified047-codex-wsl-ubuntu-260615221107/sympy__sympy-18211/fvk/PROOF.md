# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims Proved

Claim `(AS-SET-SOLVED)`: For a univariate relational `self` with symbol `x`,
if `solve_univariate_inequality(self, x, relational=False)` returns a set `S`,
then `Relational._eval_as_set()` returns `S`.

Claim `(AS-SET-NOTIMPLEMENTED)`: For a univariate relational `self` with symbol
`x`, if `solve_univariate_inequality(self, x, relational=False)` raises
`NotImplementedError`, then `Relational._eval_as_set()` returns
`ConditionSet(x, self, S.Reals)` and does not propagate that
`NotImplementedError`.

## Source-Level Proof

Start in the audited domain from PO1: `self.free_symbols` contains exactly one
symbol. The method copies that set to `syms`, asserts the size, and binds
`x = syms.pop()`.

The method then enters:

```python
try:
    return solve_univariate_inequality(self, x, relational=False)
except NotImplementedError:
    return ConditionSet(x, self, S.Reals)
```

There are two relevant paths.

Path 1, solver returns normally:

1. The call to `solve_univariate_inequality` returns set `S`.
2. The `return` inside the `try` block returns exactly `S`.
3. The `except` block is not entered.

This discharges PO2 and claim `(AS-SET-SOLVED)`.

Path 2, solver raises `NotImplementedError`:

1. The call to `solve_univariate_inequality` raises `NotImplementedError`.
2. The `except NotImplementedError` handler is selected.
3. `ConditionSet(x, self, S.Reals)` is constructed. PO4 establishes that `x`
   is a `Symbol`, `self` is a Boolean relational condition, and `S.Reals` is a
   valid base set.
4. The handler returns that `ConditionSet`.
5. The original `NotImplementedError` is not re-raised.

This discharges PO3, PO4, and claim `(AS-SET-NOTIMPLEMENTED)`.

No loop, recursion, mutable shared state, or ordering invariant is present in
the changed method, so PO7 discharges the loop/circularity part of the FVK
workflow.

## K-Level Proof Sketch

The mini semantics in `mini-sympy-as-set.k` abstracts exactly the property under
audit: the solver outcome is either `solved(S)` or `notImplemented`.

For `(AS-SET-SOLVED)`, symbolic execution applies the first semantics rule:

```k
rule
  <k> evalAsSet(R:Rel, solved(S:Set)) => .K </k>
  <result> noSet => some(S) </result>
  <exception> _ => none </exception>
```

The post-state has result `some(S)` and exception `none`, matching the claim.

For `(AS-SET-NOTIMPLEMENTED)`, symbolic execution applies the second semantics
rule:

```k
rule
  <k> evalAsSet(rel(X:Id), notImplemented) => .K </k>
  <result> noSet => some(conditionSet(X, rel(X), Reals)) </result>
  <exception> _ => none </exception>
```

The post-state has result `some(conditionSet(X, rel(X), Reals))` and exception
`none`, matching the claim.

Both proofs use one rewrite step, framing unchanged cells. No arithmetic,
map-extensionality, or circularity lemma is required.

## Adequacy Result

The English meaning of the K claims matches the intent ledger in `SPEC.md`:

- public intent requires `ConditionSet(n, Eq(...), Reals)` instead of
  `NotImplementedError` for the reported unsolved relation;
- public solved-case tests require existing solver results to be preserved;
- compatibility requires not changing direct solver behavior.

No claim relies only on candidate behavior. The fallback shape comes from the
problem statement and public hint, not from V1 alone.

## Residual Risk

The proof is partial correctness only: it proves the returned value for each
modeled branch if the method reaches that branch. Termination is not separately
proved, but the changed method has no loop.

The mini-K semantics is an abstraction of Python/SymPy execution. It is adequate
for the branch property under audit because it distinguishes the passing and
failing cases that matter: solver success versus solver `NotImplementedError`.
It does not prove solver correctness, periodic `as_set()` behavior, or
multivariate behavior.

The proof is constructed, not machine-checked. Running K later is required to
upgrade the formal result to machine-verified.

## Machine-Check Commands

These commands are intentionally recorded but not run:

```sh
cd fvk
kompile mini-sympy-as-set.k --backend haskell
kast --backend haskell relational-as-set-spec.k
kprove relational-as-set-spec.k
```

Expected result after machine checking: `kprove` returns `#Top`.

## Test Recommendation

Do not delete tests based on this constructed proof. Existing univariate
relational tests are still useful until the K proof is machine-checked.

Recommended test to add in the normal project test suite:

```python
assert Eq(n*cos(n) - 3*sin(n), 0).as_set() == \
    ConditionSet(n, Eq(n*cos(n) - 3*sin(n), 0), S.Reals)
```

No test files were modified in this task.
