# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or test command was run.

## Claims

The K-style claims are in `fvk/imageset-real-intersection-spec.k` and use the
minimal property-preserving model in `fvk/mini-sympy-sets.k`.

## Proof Sketch

### C1: Reported Intersection

Start with `intersectReals(Image(IssueExpr, Integers))`.

The mini semantics rewrites:

1. `realPart(IssueExpr) => Id`.
2. `imagPart(IssueExpr) => IssueImag`.
3. `zeroSet(IssueImag) => IssueRoots`, modeling `FiniteSet(-1, 1)`.
4. `singularSet(IssueExpr) => EmptySet`.
5. `Integers /\ IssueRoots => IssueRoots`.
6. `IssueRoots \ EmptySet => IssueRoots`.
7. `imageSet(Id, IssueRoots) => IssueResult`.

Therefore `intersectReals(Image(IssueExpr, Integers)) => IssueResult`, where
`IssueResult` is the model's name for `FiniteSet(-1, 1)`.

### C2: Nonmembership of 2

Using C1, the membership query reduces to `contains(2, IssueResult)`, and the
semantics has `contains(2, IssueResult) => false`.

### C3: Membership of -1 and 1

Using C1, the membership queries reduce to `contains(-1, IssueResult)` and
`contains(1, IssueResult)`. The semantics rewrites both to `true`.

### C4: Denominator Exclusion Frame

For `Image(OneOverN, Integers)`, the model rewrites:

1. `imagPart(OneOverN) => Zero`.
2. `zeroSet(Zero) => Integers`.
3. `singularSet(OneOverN) => IssueRootsZero`, modeling the denominator root
   `{0}`.
4. `(Integers /\ Integers) \ IssueRootsZero` reduces to `NonZeroIntegers` in
   the intended model.
5. The result is `imageSet(OneOverN, NonZeroIntegers)`.

This captures the frame condition that undefined denominator points are
excluded and the original image over all integers is not silently proven to be a
real subset.

## Source-Level Proof Connection

V1 implements the same transitions:

- `_solutions_from_linear_factors(im)` computes `FiniteSet(*xis)`.
- The real-intersection branch uses `base_set = base_set.intersect(real_solutions)`.
- Denominator roots are computed from each denominator expression and subtracted.
- Fallback unknown zero sets become `ConditionSet(n, Eq(im, 0), base_set)`.

Static source inspection supports the reported path: `expand_complex` is called
with `mul=False` and `multinomial=False`, and `Mul.as_real_imag` preserves the
reported product factors, so `(n - 1)` and `(n + 1)` are visible to
`solve_linear`.

## Commands To Machine-Check Later

```sh
kompile fvk/mini-sympy-sets.k --backend haskell
kast --backend haskell fvk/imageset-real-intersection-spec.k
kprove fvk/imageset-real-intersection-spec.k
```

Expected result after a successful machine check: `#Top`.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics is intentionally narrow and models the observable set and
  membership behavior relevant to the issue, not all of SymPy.
- No termination proof is needed for this branch-level algebraic rewrite.
- Tests must not be removed based on this constructed proof alone.

