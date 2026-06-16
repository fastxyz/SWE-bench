# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims Proved in the Constructed Model

The K claims are in `point-scalar-spec.k` and use the semantics fragment in
`mini-python-point.k`.

1. `scalarValue(S) * point(Cs) => point(scale(Cs, S))`
2. `point(Cs) * scalarValue(S) => point(scale(Cs, S))`
3. `scalarValue(S) * point(Cs) => point(Cs) * scalarValue(S)`
4. `point(Ps) + (scalarValue(S) * point(Qs)) =>
   point(addCoords(Ps, scale(Qs, S)))` when dimensions match
5. `scalarValue(S) + point(Cs) => symAdd(scalarValue(S), point(Cs))`
6. `scalarValue(S) - point(Cs) =>
   symAdd(scalarValue(S), point(negCoords(Cs)))`
7. `scalarValue(S) / point(Cs) => symDiv(scalarValue(S), point(Cs))`

## Proof Sketch

For claim 1, symbolic execution starts with a scalar value on the left and a
point on the right. In the V1 dispatch model, `Point._op_priority = 10.001` is
greater than ordinary `Expr._op_priority = 10.0`, so `Expr.__mul__` routes to
`Point.__rmul__`. The `pointRMul` rule represents that call. V1 implements
`__rmul__` as `self*factor`, so the next step is the same coordinate-scaling
transition as `Point.__mul__`, yielding `point(scale(Cs, S))`.

For claim 2, symbolic execution uses the existing right-multiplication rule:
`point(Cs) * scalarValue(S)` calls `pointMul`, which scales each coordinate and
returns `point(scale(Cs, S))`. This is unchanged from the pre-existing
`Point.__mul__` path.

Claim 3 follows by transitivity from claims 1 and 2: both scalar-left and
scalar-right multiplication reach the same `point(scale(Cs, S))` post-state.

For claim 4, evaluate the inner multiplication first. The left-scalar branch
uses claim 1 and reduces `scalarValue(S) * point(Qs)` to
`point(scale(Qs, S))`. Point addition then applies the same-dimensional point
addition rule and reaches `point(addCoords(Ps, scale(Qs, S)))`. The
right-scalar expression uses claim 2 for the inner multiplication and reaches
the same post-state, so the composed expressions are equivalent.

For claims 5-7, adding `_op_priority` means ordinary `Expr` operations can
consider `Point` reflected methods. V1 supplies explicit `Point` reflected
methods for add, subtract, and divide. Symbolic execution therefore takes the
`pointRAdd`, `pointRSub`, or `pointRDiv` transition and constructs the same
symbolic forms that `Expr` would previously have produced without point
priority: `Add(expr, point)`, `Add(expr, -point)`, and `Mul(expr, Pow(point,
-1))`.

No loop circularities are needed because the audited code path contains no
loops or recursion.

## Adequacy Gate

The adequacy files are present:

- `INTENT_SPEC.md`
- `PUBLIC_EVIDENCE_LEDGER.md`
- `FORMAL_SPEC_ENGLISH.md`
- `SPEC_AUDIT.md`
- `PUBLIC_COMPATIBILITY_AUDIT.md`

`SPEC_AUDIT.md` marks every formal-English claim as passing against the
intent. No required behavior is marked fail or ambiguous.

## Residual Risk

The proof is constructed over a mini semantics, not machine-checked against
the full Python/SymPy runtime. It proves partial correctness of the modeled
operator dispatch and coordinate-scaling behavior. It does not prove
termination, but there are no loops in scope.

## Machine Check Commands

Run later in an environment with K installed:

```sh
kompile fvk/mini-python-point.k --backend haskell
kast --backend haskell fvk/point-scalar-spec.k
kprove fvk/point-scalar-spec.k
```

Expected machine-checked result: all claims return `#Top`.

## Test Redundancy Recommendation

No tests were read as authoritative or modified. In a normal development flow,
unit tests that assert only in-domain scalar-left/right equivalence would be
subsumed after machine-checking the claims. Boundary, integration, and full
SymPy dispatch tests should be kept.
