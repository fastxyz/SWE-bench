# Proof

Status: constructed, not machine-checked.

No `kompile`, `kprove`, Python, or tests were run. The commands below are the
commands to run in an environment where K is available.

## Claims

- C1: `_sqrt_match(4 + I)` reaches `noMatch`.
- C2: `split_surds(4 + I)` reaches `(1, 0, 4 + I)`.
- C3: `rad_rationalize(1, 4 + I)` reaches `(1, 4 + I)`.
- C4: `rad_rationalize(1, 1 + cbrt(2))` reaches `(1, 1 + cbrt(2))`.
- C5: `rad_rationalize(1, sqrt(2) + I)` reaches `(sqrt(2) - I, 3)`.
- C6: the documented `split_surds` regular-surd example reaches its documented
  grouping.

## Constructed Proof Sketch

C1 follows from the `allPosRatSquares(add2(four, iUnit)) => false` equation and
the V1 `_sqrt_match` rule that returns `noMatch` when not all addend squares are
rational positive. This models the new `sq.is_Rational and sq.is_positive`
guard.

C2 follows by one `splitSurds(add2(four, iUnit))` rewrite to
`split(one, zero, add2(four, iUnit))`. This models V1's `if not surds` guard and
therefore avoids `_split_gcd`.

C3 follows by one `radRat` no-progress rewrite. The no-surd split means there is
no square-root component `a`, matching V1's `if not a: return num, den`.

C4 follows by the same no-progress rewrite as C3. The cube-root term is not an
explicit square-root `Pow(..., S.Half)`, so recursion is not entered.

C5 follows by transitivity. The first rewrite models the existing supported
sqrt path:

```text
radRat(one, add2(sqrt2, iUnit))
=> radRat(sqrt2MinusI, three)
=> pair(sqrt2MinusI, three)
```

The second rewrite is the non-Add/base denominator case. This proves the V1
guard does not turn `sqrt(2)+I` into a no-op.

C6 follows by one `splitSurds(docDen)` rewrite to the documented grouping.

## Recursive/Loop Obligations

The audited mini-semantics contains no loops. The only modeled recursive edge is
the finite public `rad_rationalize(1, sqrt(2)+I)` frame case, which takes one
recursive step and then reaches the non-Add base case. The unbounded recursive
family of the full SymPy helper is outside this finite model and remains a
model-scope boundary, not a concrete V1 counterexample.

## Exact Commands

Run from the repository workspace root:

```sh
cd fvk
kompile mini-sympy-surds.k --backend haskell --main-module MINI-SYMPY-SURDS --syntax-module MINI-SYMPY-SURDS-SYNTAX
kprove sqrtdenest-spec.k --definition mini-sympy-surds-kompiled --spec-module SQRTDENEST-SPEC
```

Expected result if the constructed claims discharge: `#Top`.

## Honesty Gate

This proof is constructed, not machine-checked. No test removal is recommended.
The proof supports the code-audit decision only within the finite public-issue
model described in `SPEC.md`.

## Test Recommendations

- Keep existing tests. No tests were modified.
- Add regression coverage in the fixed suite for the public examples if this
  were a normal development branch: `sqrtdenest` with the `4 + I` radicand,
  `rad_rationalize(1, 4 + I)`, and `rad_rationalize(1, 1 + cbrt(2))`.
- Do not remove any tests unless the K claims are machine-checked and the test
  is shown to be an in-domain point subsumed by the proof.
