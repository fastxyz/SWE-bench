# Proof

Status: constructed, not machine-checked.

No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Claims

The proof package consists of:

- `mini-latex-printer.k`: minimal printer-shape semantics.
- `subs-latex-spec.k`: reachability claims for strict parenthesizing,
  `_print_Subs` shape, the issue example, and the legacy diagnostic
  counterexample.

There are no loops or recursive functions in the modeled fragment, so there are
no circularity claims.

## Constructed proof sketch

`PAREN-LOW-STRICT`

Given `prec(E) <Int 50`, the strict `parenthesize` rule rewrites
`parenthesize(E, 50, true)` to `paren(render(E))`.

`PAREN-NONLOW-STRICT`

Given `notBool (prec(E) <Int 50)`, the strict `parenthesize` rule rewrites
`parenthesize(E, 50, true)` to `render(E)`.

`SUBS-LOW-PRECEDENCE`

`printSubs(E, A)` rewrites to
`subsTex(parenthesize(E, 50, true), A)`. Under `prec(E) <Int 50`, the
`PAREN-LOW-STRICT` reasoning rewrites the inner term to `paren(render(E))`.
The assignment suffix `A` is framed through unchanged.

`SUBS-NONLOW-PRECEDENCE`

`printSubs(E, A)` rewrites to
`subsTex(parenthesize(E, 50, true), A)`. Under
`notBool (prec(E) <Int 50)`, the `PAREN-NONLOW-STRICT` reasoning rewrites the
inner term to `render(E)`. The assignment suffix `A` is framed through
unchanged.

`ISSUE-EXAMPLE`

`printMulWithCoeff(3, addExpr, assignOne)` rewrites to
`mulTex(numTex(3), printSubs(addExpr, assignOne))`. Since
`prec(addExpr) => 40` and `40 <Int 50`, `SUBS-LOW-PRECEDENCE` applies and the
result is `mulTex(numTex(3), subsTex(paren(rawAdd), assignOne))`.

`LEGACY-COUNTEREXAMPLE-DIAGNOSTIC`

The diagnostic legacy function rewrites `printSubsLegacy(E, A)` directly to
`subsTex(render(E), A)`. Therefore the issue input shape rewrites to
`mulTex(numTex(3), subsTex(rawAdd, assignOne))`, matching the reported bad
shape and localizing the old direct-rendering mechanism.

## Verification conditions

The only side conditions are integer precedence comparisons:

- `prec(addExpr) = 40`, so `40 <Int 50`.
- `prec(mulExpr) = 50`, so `notBool (50 <Int 50)`.
- `prec(derivativeExpr) = 50`, so `notBool (50 <Int 50)`.
- `prec(atomExpr) = 1000`, so `notBool (1000 <Int 50)`.

These are first-order integer/boolean simplifications in the bundled tier.

## Residual risk

This proof is constructed, not machine-checked. It does not claim `#Top`.

The mini semantics abstracts concrete LaTeX strings to shape terms. This is
adequate for the audited property because it preserves the observable
difference between raw additive output and parenthesized additive output, and it
preserves the assignment suffix as an explicit term.

The proof is partial correctness for the modeled rendering functions. It does
not prove full SymPy printer coverage, termination, or unrelated formatting
behavior.

## Reproduce the machine check

Run these commands from the workspace root when a K environment is available:

```sh
cd fvk
kompile mini-latex-printer.k --backend haskell
kprove subs-latex-spec.k --definition mini-latex-printer-kompiled --spec-module SUBS-LATEX-SPEC
```

Optional parse sanity command, subject to local K version support for parsing
claim files directly:

```sh
cd fvk
kast subs-latex-spec.k --definition mini-latex-printer-kompiled --module SUBS-LATEX-SPEC --sort Claim
```

Expected result after successful machine checking: `kprove` returns `#Top`.

## Test recommendations

Do not delete or modify tests. If the K commands above later return `#Top`, the
non-additive unit point represented by `Subs(x*y, ...)` would be subsumed by
`SUBS-NONLOW-PRECEDENCE` within the modeled fragment, but keeping it remains
reasonable integration compatibility coverage for the real printer.
