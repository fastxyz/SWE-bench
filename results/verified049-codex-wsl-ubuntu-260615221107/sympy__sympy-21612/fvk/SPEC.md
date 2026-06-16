# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Target

The verified target is the V1 change in `repo/sympy/printing/str.py`, inside `StrPrinter._print_Mul`, for the path that moves a commutative `Pow` factor with exponent `-1` into the denominator.

The public issue is about the string representation of expressions produced from LaTeX fractions. Source inspection shows the parser constructs fractions as `Mul(expr_top, Pow(expr_bot, -1, evaluate=False), evaluate=False)`, so the denominator expression reaches `_print_Mul` as the base of a reciprocal `Pow`.

## Public Intent Ledger

| ID | Evidence | Obligation |
|---|---|---|
| I1 | `benchmark/PROBLEM.md` reports `\frac{\frac{a^3+b}{c}}{\frac{1}{c^2}}` displaying as `((a**3 + b)/c)/1/(c**2)`. | The outer denominator must remain grouped. |
| I2 | The expected display is `((a**3 + b)/c)/(1/(c**2))`. | A denominator that is itself a reciprocal must be printed as one denominator expression. |
| I3 | The simplified failure is `\frac{a}{\frac{1}{b}}` displaying as `a/1/b`. | The minimal nested reciprocal denominator must print as `a/(1/b)`. |
| I4 | Public hint says the expression args are already `(a, 1/(1/b))`. | The parser tree is already correct; the printer must preserve the tree's grouping. |
| I5 | Existing public test for issue 14160 expects a `Mul(y, y)` denominator base to print grouped. | Existing compound-`Mul` grouping must not regress. |
| I6 | Existing simple quotient tests expect forms like `x/y`. | Simple denominator output should remain compact. |

See `PUBLIC_EVIDENCE_LEDGER.md` for the fuller provenance table.

## Formal Domain

The formal model covers the finite branch decision for a denominator factor with exponent exactly `-1`:

1. base kind `powK`, arity not equal to `1`: must be parenthesized;
2. base kind `mulK`, arity not equal to `1`: must remain parenthesized;
3. simple atomic base: must not be newly parenthesized.

The model tracks the observable property that matters here: whether denominator text is wrapped before it is placed after the outer slash. It intentionally abstracts away the rest of SymPy's expression tree and ordering machinery.

## K Artifacts

`mini-str-printer.k` defines a minimal printer-shape semantics:

`printMul(numerator, reciprocal(base(kind, arity, text))) => slashText(numerator, denomText(base(kind, arity, text)))`

`str-printer-spec.k` states four claims:

1. nested reciprocal base `powK` prints as `a/(1/b)`;
2. the original issue shape with `1/(c**2)` remains grouped;
3. the existing `Mul`-base issue 14160 shape remains grouped;
4. an atomic denominator stays unwrapped.

## Expected Machine Check

The following commands are recorded for later machine checking only and were not executed:

```sh
kompile fvk/mini-str-printer.k --backend haskell
kast --backend haskell fvk/str-printer-spec.k
kprove fvk/str-printer-spec.k
```

Expected result if the mini semantics and claims are accepted by K: `kprove` returns `#Top` for all four claims.

## Specification Verdict

The V1 source change satisfies the intent-scoped specification: it adds `Pow` to the same denominator-parenthesizing guard that already handled compound `Mul` bases. No source change beyond V1 is justified by the FVK findings.
