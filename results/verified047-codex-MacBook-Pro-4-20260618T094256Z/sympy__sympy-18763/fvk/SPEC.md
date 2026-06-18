# FVK Spec

Status: constructed, not machine-checked.

## Modeled observable

The K model abstracts concrete LaTeX strings into shape terms that preserve the
property under audit:

| K term | LaTeX shape represented |
|---|---|
| `rawAdd` | `- x + y` or another additive expression printed without grouping |
| `paren(rawAdd)` | `\left(- x + y\right)` |
| `rawMul` | `x y` or another multiplicative expression printed without grouping |
| `subsTex(T, assignOne)` | `\left. T \right|_{\substack{ x=1 }}` |
| `subsTex(T, assignTwo)` | `\left. T \right|_{\substack{ x=1\\ y=2 }}` |
| `mulTex(numTex(3), S)` | `3 S` |

This abstraction distinguishes the reported failing shape from the desired shape:
`subsTex(rawAdd, assignOne)` is not equal to
`subsTex(paren(rawAdd), assignOne)`.

## Function contracts

1. `parenthesize(E, 50, true)` returns `paren(render(E))` when `prec(E) < 50`.
   In the modeled domain this is the additive expression case.

2. `parenthesize(E, 50, true)` returns `render(E)` when `prec(E) >= 50`. In the
   modeled domain this covers multiplicative, derivative-precedence, and atomic
   expressions.

3. `printSubs(E, A)` returns `subsTex(paren(render(E)), A)` for additive
   expressions and preserves the assignment list `A`.

4. `printSubs(E, A)` returns `subsTex(render(E), A)` for non-additive modeled
   expressions and preserves the assignment list `A`.

5. `printMulWithCoeff(3, addExpr, assignOne)` returns
   `mulTex(numTex(3), subsTex(paren(rawAdd), assignOne))`, corresponding to the
   issue's requested LaTeX shape.

6. `printMulWithCoeffLegacy(3, addExpr, assignOne)` returns
   `mulTex(numTex(3), subsTex(rawAdd, assignOne))`. This is a diagnostic
   counterexample for the legacy direct-rendering mechanism, not a candidate
   behavior to preserve.

## Public evidence ledger

The public ledger is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- `E3` is marked SUSPECT because it is the reported buggy display.
- `E4` provides the expected additive-expression postcondition.
- `E5` provides the non-additive frame condition.
- `E6` and `E7` are implementation/modeling evidence, not standalone intent.

## Loops and recursion

No loops or recursive calls are in the audited printer fragment. Therefore no
circularity claims are required for this FVK run.

## Preconditions and side conditions

The domain is the modeled LaTeX printer fragment: additive expressions,
multiplicative expressions, atomic expressions, derivative-precedence
expressions, and one- or two-assignment `Subs` suffixes. No hidden test behavior,
external data, or full Python semantics is assumed.
