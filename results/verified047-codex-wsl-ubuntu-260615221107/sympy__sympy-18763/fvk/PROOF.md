# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims Proved on Paper

The formal claims are in `fvk/latex-subs-spec.k` and use the mini semantics in
`fvk/mini-python-printing.k`.

1. Issue-shaped claim:
   `printMulFactor("3", printSubs(expr(40, "- x + y"), "x", "1"))` reaches
   `3 \left. \left(- x + y\right) \right|_{\substack{ x=1 }}`.

2. Low-precedence body claim:
   if `PREC < 50`, then `printSubs(expr(PREC, BODY), OLD, NEW)` reaches
   `\left. \left(BODY\right) \right|_{\substack{ OLD=NEW }}`.

3. Frame claim:
   if `PREC >= 50`, then `printSubs(expr(PREC, BODY), OLD, NEW)` reaches
   `\left. BODY \right|_{\substack{ OLD=NEW }}`.

## Proof Sketch

The mini semantics models only the observable axis under audit: whether the
substituted expression body is wrapped before `_print_Mul` prefixes the rendered
factor.

For PO-001, symbolic execution starts at:

```k
<k> printSubs(expr(PREC, BODY), OLD, NEW) </k>
requires PREC <Int 50
```

The `printSubs` rule rewrites the body through `parenthesize(expr(PREC, BODY),
50)`. Under the side condition `PREC <Int 50`, the first `parenthesize` rule
applies and rewrites the body to:

```text
\left(BODY\right)
```

String concatenation then yields the low-precedence postcondition. This proves
PO-001 by symbolic execution and consequence on `PREC <Int 50`.

For PO-002, the same `printSubs` rule is used, but the side condition is
`PREC >=Int 50`. The second `parenthesize` rule applies, yielding `BODY`
without added parentheses. Concatenation yields the frame postcondition.

For PO-003, strict evaluation of the second argument to `printMulFactor`
first reduces the nested `printSubs(expr(40, "- x + y"), "x", "1")`. Since
`40 <Int 50`, PO-001 applies and the factor becomes:

```text
\left. \left(- x + y\right) \right|_{\substack{ x=1 }}
```

The `printMulFactor` rule then prefixes `"3 "` to that factor, producing the
issue's expected string.

There are no loops or recursive functions in the audited code path, so no
circularity claim is required.

## Exact Commands To Machine-Check Later

Run these from the repository root in an environment with K installed:

```sh
cd fvk
kompile mini-python-printing.k --backend haskell
kast --backend haskell latex-subs-spec.k
kprove latex-subs-spec.k
```

Expected result after a successful machine check: `#Top` for all claims.

## Test Guidance

Tests to add or keep after this source fix:

- Add or keep an issue regression for
  `latex(3*Subs(-x + y, (x,), (1,)))`.
- Keep the existing public `Subs(x*y, ...)` coverage unless and until the K
  proof is machine-checked and maintainers decide the point test is redundant.

No test files were edited.
