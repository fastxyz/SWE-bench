# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or test command was executed.

## Reproduce the machine check later

These commands are recorded for a future environment with K installed:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/poly-element-as-expr-spec.k
kprove fvk/poly-element-as-expr-spec.k
```

Expected machine-check result after the semantics/spec parse successfully:
`#Top` for all claims.

## Function proof: `PolyElement.as_expr`

The method has one conditional chain and one return. There are no loops or
recursive calls, so no circularity claim is needed.

### Case 1: no supplied symbols

Precondition: `symbols` is empty.

Symbolic execution enters `if not symbols` and assigns
`symbols = self.ring.symbols`. The wrong-arity branch is skipped. The return
calls `expr_from_dict(self.as_expr_dict(), *symbols)`, now with
`symbols == self.ring.symbols`. This proves PO-1 and claim
`POLY-AS-EXPR-DEFAULT`.

### Case 2: supplied symbols with matching arity

Precondition: `symbols` is non-empty and
`len(symbols) == self.ring.ngens`.

Symbolic execution skips the empty-varargs fallback. The `elif` guard
`len(symbols) != self.ring.ngens` is false, so execution reaches the return
without reassigning `symbols`. The return therefore calls
`expr_from_dict(self.as_expr_dict(), *symbols)` with the caller-supplied tuple.
This proves PO-2 and claim `POLY-AS-EXPR-SUPPLIED`.

This is the V1 repair over the pre-fix behavior: the pre-fix `else` branch
overwrote `symbols` with `self.ring.symbols` even in this case.

### Case 3: supplied symbols with wrong arity

Precondition: `symbols` is non-empty and
`len(symbols) != self.ring.ngens`.

Symbolic execution skips the empty-varargs fallback and enters the `elif`
branch, raising `ValueError`. The expression-construction return is unreachable
on this path. This proves PO-3 and claim `POLY-AS-EXPR-BAD-ARITY`.

## Helper proof: `expr_from_dict`

`expr_from_dict(rep, *gens)` constructs each term by zipping `gens` with a
monomial and appending `Pow(g, m)` for nonzero exponents. Therefore the tuple
passed as `gens` is the tuple used positionally in the returned expression. This
proves PO-4 and is why preserving the same-arity varargs tuple fixes the issue.

## Compatibility proof: `FracElement.as_expr`

`FracElement.as_expr(*symbols)` returns
`self.numer.as_expr(*symbols)/self.denom.as_expr(*symbols)`. Because the wrapper
forwards the exact varargs tuple, PO-2 composes through numerator and
denominator conversion. This proves PO-5 and claim `FRAC-AS-EXPR-SUPPLIED`.

## Adequacy and completeness

The formal claims cover every branch class in the audited method:

- empty varargs;
- non-empty matching arity;
- non-empty wrong arity.

The model keeps the bug-relevant observable, the `Symbols` value passed to
`exprFromDict`, so it distinguishes the repaired same-arity branch from the
pre-fix branch that used `ringSymbols(P)`.

## Residual risk

The proof is constructed but not machine-checked. The trusted base is the
adequacy of the mini-semantics for this branch-level behavior, the K
reachability proof system, and eventual successful execution of the recorded
`kompile`/`kprove` commands. No termination proof is needed for the audited
method because it contains no loop or recursion.

## Test-redundancy recommendation

Conditioned on future machine-checking, visible in-domain tests for no-symbol
conversion, same-arity conversion, and wrong-arity rejection would be subsumed
by PO-1, PO-2, and PO-3. Tests should not be removed in this task. F-2
recommends adding distinct-symbol coverage, but the task forbids modifying test
files.
