# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or tests were run.

## Claims Proved

The narrow FVK model proves these source-level obligations:

- `CONTAINS-AS-SET-SYMBOL`: symbolic `Contains(X, S).as_set()` reaches Set `S`.
- `CONDITIONSET-CONTAINS-FLATTEN`: `ConditionSet(X, Contains(X, S), UniversalSet)` normalizes to `S`.
- `BOOLEAN-EVAL-AS-SET-ONE-FREE`: a one-free-symbol Boolean fallback reaches `ConditionSet(X, P)`.
- `CONTAINS-AS-SET-EMPTY`: false/empty symbolic membership reaches `EmptySet`.

The K artifacts are:

- `fvk/mini-sympy-as-set.k`
- `fvk/contains-as-set-spec.k`

## Proof Sketch

1. Symbolic execution of `Contains.as_set()` on `Contains(X, S)` with `X.is_Symbol` follows the V1 branch:

   `Contains.as_set(Contains(X, S)) => ConditionSet(X, Contains(X, S), UniversalSet)`.

2. Symbolic execution of `ConditionSet.__new__` reaches the existing flattening rule because the condition is `Contains`, the bound symbol equals the membership subject, and the second argument is a Set:

   `ConditionSet(X, Contains(X, S), UniversalSet) => intersect(S, UniversalSet)`.

3. The existing Set identity for `UniversalSet` discharges the final step:

   `intersect(S, UniversalSet) => S`.

4. For `S = EmptySet`, the same path produces:

   `intersect(EmptySet, UniversalSet) => EmptySet`.

5. For a generic Boolean `P` with one free symbol, symbolic execution of V1's `Boolean._eval_as_set()` follows:

   `BooleanEvalAsSet(P) => ConditionSet(freeSymbol(P), P, UniversalSet)`.

6. The multivariate branch is not proved as total. It is a specified boundary because public intent explicitly says multivariate `as_set` is not implemented.

There are no loops or recursive functions in the audited code path, so no circularity claim is required.

## Adequacy Check

The English meaning of the K claims matches `fvk/SPEC.md`:

- The claims return a Set for symbolic membership, matching I1 and I3.
- The claims use `ConditionSet` for one-free-symbol Booleans, matching I2.
- The false/empty case returns `EmptySet`, matching I4.
- The claims do not assert multivariate support, matching the public hint's stated boundary.

## Machine Check Commands Not Run

These are the commands a future environment with K installed should run:

```sh
cd fvk
kompile mini-sympy-as-set.k --backend haskell
kast --backend haskell contains-as-set-spec.k
kprove contains-as-set-spec.k
```

Expected result if the mini semantics and claims parse as written: `kprove` reduces the claims to `#Top`.

## Test Guidance

Recommendation-only, conditioned on machine-checking and on the project's normal test policy:

- Add/keep tests for `Contains(x, S.Reals).as_set() == S.Reals`.
- Add/keep tests for `Contains(x, FiniteSet(y)).as_set() == FiniteSet(y)` because the old visible test is SUSPECT.
- Add/keep tests for `Contains(x, S.EmptySet, evaluate=False).as_set() is S.EmptySet` or the evaluated false path.
- Keep integration tests that exercise `Piecewise` with `Contains` because this proof covers only the local conversion contract, not all `Piecewise` behavior.

No tests were removed or edited.
