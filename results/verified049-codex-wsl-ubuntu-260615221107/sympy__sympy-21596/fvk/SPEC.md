# FVK Spec

Status: constructed, not machine-checked.

## Unit Under Audit

`repo/sympy/sets/handlers/intersection.py::intersection_sets(self, other)` for
the univariate `ImageSet` and `other == S.Reals` branch.

## Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The binding public obligations are:

- The reported `ImageSet` intersects `S.Reals` as `FiniteSet(-1, 1)`.
- `2` is not a member of that real intersection.
- Real intersection keeps parameter values that make the imaginary part zero.
- Denominator-zero parameter values remain excluded, preserving the public
  `1/n` `is_subset(S.Reals) is None` behavior.
- The in-repo expectation using `Complement(S.Integers, FiniteSet((-1, 1)))` is
  SUSPECT because it conflicts with the issue's correct output.

## Functional Contract

For a univariate image set `ImageSet(Lambda(n, f(n)), base_set)` intersected
with `S.Reals`:

1. Let `f(n) = re(n) + I*im(n)` after substituting a real dummy for `n`.
2. If `im(n)` is identically zero, the result is the image of `re(n)` over the
   original base set, subject to denominator exclusions.
3. If `im(n)` is provably nonzero, the result is `S.EmptySet`.
4. If `im(n)` has known linear-factor zero roots, the result base is
   `base_set.intersect(FiniteSet(*roots))`.
5. If zero roots are not enumerated, the result base is
   `ConditionSet(n, Eq(im(n), 0), base_set)`.
6. For each denominator depending on `n`, known denominator roots are removed
   from the current result base; otherwise a denominator-zero `ConditionSet`
   over the current result base is removed.
7. The final result is `imageset(Lambda(n, re(n)), result_base)`.

## Reported-Case Contract

For `f(n) = n + I*(n - 1)*(n + 1)` and `base_set = S.Integers`:

- `re(n) = n`.
- `im(n) = (n - 1)*(n + 1)`.
- `zero_roots(im) = {-1, 1}`.
- There are no denominator roots.
- `result_base = S.Integers.intersect(FiniteSet(-1, 1)) = FiniteSet(-1, 1)`.
- `imageset(Lambda(n, n), FiniteSet(-1, 1)) = FiniteSet(-1, 1)`.
- Therefore `2 in result` is false.

## Formal Core

The accompanying formal artifacts are:

- `fvk/mini-sympy-sets.k`: a minimal K-style algebra model that preserves the
  observable property under audit, namely set result shape and membership.
- `fvk/imageset-real-intersection-spec.k`: claims for the reported result,
  membership of `2`, membership of `-1` and `1`, and denominator-exclusion frame.

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-sympy-sets.k --backend haskell
kast --backend haskell fvk/imageset-real-intersection-spec.k
kprove fvk/imageset-real-intersection-spec.k
```

