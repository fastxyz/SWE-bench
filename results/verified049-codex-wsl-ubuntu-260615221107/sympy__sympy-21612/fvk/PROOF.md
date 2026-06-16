# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Claims Proved in the Mini Semantics

The mini semantics in `mini-str-printer.k` models the branch that matters for the issue:

```k
printMul(N, reciprocal(B)) => slashText(N, denomText(B))
```

The V1 repair is captured by these denominator rules:

```k
denomText(base(mulK, A, T)) => parenText(T) requires A =/=Int 1
denomText(base(powK, A, T)) => parenText(T) requires A =/=Int 1
```

The formal claims in `str-printer-spec.k` cover the repaired `Pow` case, the preserved `Mul` case, the original nested `1/(c**2)` family member, and the unchanged atomic case.

## Proof Sketch

For the simplified issue case, start with:

```k
<k> printMul(symA, reciprocal(base(powK, 2, slashText(oneText, symB)))) </k>
```

Apply the `printMul` rule:

```k
<k> slashText(symA, denomText(base(powK, 2, slashText(oneText, symB)))) </k>
```

The side condition `2 =/=Int 1` holds, so apply the V1 `powK` denominator rule:

```k
<k> slashText(symA, parenText(slashText(oneText, symB))) </k>
```

That is the abstract observable for `a/(1/b)`, not the ungrouped `a/1/b`.

The original issue shape is identical except the denominator text is `slashText(oneText, cSquared)` and the numerator text is `fracNumer`; the same `powK` rule wraps it.

For the issue 14160 frame condition, apply `printMul` to `base(mulK, 2, yTimesY)`, then apply the preserved `mulK` denominator rule. The result is `slashText(symX, parenText(yTimesY))`, preserving `x/(y*y)`.

For the simple atomic denominator frame condition, apply `printMul` to `base(atomK, 0, symY)`, then apply the atom rule. The result is `slashText(symX, symY)`, preserving the compact `x/y` shape.

There are no loops or recursive calls, so there are no circularity claims or termination variants. The proof is finite symbolic execution plus the integer side condition `A =/=Int 1` in the compound cases.

## Adequacy Check

The proof does not derive expected strings from the current code alone. The expected grouping comes from the public issue's expected output and simplified failure. Existing public tests provide frame evidence for `Mul` bases and simple quotients. The formal observable includes explicit `parenText`, so it distinguishes the failing and passing outputs.

## Commands for Later Machine Checking

These commands are recorded as required by FVK and were not executed:

```sh
kompile fvk/mini-str-printer.k --backend haskell
kast --backend haskell fvk/str-printer-spec.k
kprove fvk/str-printer-spec.k
```

Expected machine-check result after successful compilation: `kprove` returns `#Top` for all claims.

## Test Guidance

Do not delete tests based on this constructed proof. After machine checking, point tests for `a/(1/b)`, the original nested fraction, `x/(y*y)`, and `x/y` would be subsumed by the formal claims in the mini semantics, but integration tests around the real parser/printer pipeline should still be kept because the mini semantics does not model full SymPy.
