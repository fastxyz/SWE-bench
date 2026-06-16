# PROOF

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Summary

The proof is a symbolic execution over the abstract printer semantics in `fvk/mini-python-printing.k` and the claims in `fvk/strprinter-spec.k`. It proves partial correctness of the relevant printer paths: if the audited `StrPrinter` method is entered with a composite expression in the modeled domain, the returned string is composed from active-printer renderings of operand subexpressions.

## PO-REL

Start state:

```k
<k> printStr(true, RelExpr("==", Sym("x"), Rat(1, 2))) </k>
```

Symbolic execution applies the `RelExpr` rule:

```text
relName("==") + "(" + printStr(true, Sym("x")) + ", " + printStr(true, Rat(1, 2)) + ")"
```

Then simplification gives:

- `relName("==") => "Eq"`
- `printStr(true, Sym("x")) => "x"`
- `printStr(true, Rat(1, 2)) => "S(1)/2"`

By transitivity, the final string is `Eq(x, S(1)/2)`.

The old V1-predecessor behavior would have used `rawStr(Rat(1, 2)) => "1/2"`, failing the claim. V2 uses `self._print(expr.lhs)` and `self._print(expr.rhs)`, matching the claim.

## PO-LIMIT

Start state:

```k
<k> printStr(true, LimitExpr(Sym("x"), Sym("x"), Rat(1, 2), "+")) </k>
```

The default-direction `LimitExpr` rule rewrites to:

```text
"Limit(" + printStr(true, Sym("x")) + ", "
           + printStr(true, Sym("x")) + ", "
           + printStr(true, Rat(1, 2)) + ")"
```

The subterms simplify to `x`, `x`, and `S(1)/2`, so the final string is `Limit(x, x, S(1)/2)`.

The explicit-direction branch has the same operand proof for `e`, `z`, and `z0`; the direction marker is a quoted direction token and is intentionally framed as the existing string marker.

## PO-PYTHON

Start state:

```k
<k> pythonProgram(RelExpr("==", Sym("x"), Sym("y"))) </k>
```

The `pythonProgram` rule expands to:

```text
symbolDecls(collectSymbols(RelExpr("==", Sym("x"), Sym("y"))))
+ "e = "
+ printStr(false, RelExpr("==", Sym("x"), Sym("y")))
```

The collection rules give:

```text
collectSymbols(RelExpr("==", Sym("x"), Sym("y")))
=> union(add("x", .SymSet), add("y", .SymSet))
=> "x" ; "y" ; .SymSet
```

Therefore `symbolDecls(...)` yields:

```text
x = Symbol('x')
y = Symbol('y')
```

The expression rendering yields `Eq(x, y)`. The final string is:

```text
x = Symbol('x')
y = Symbol('y')
e = Eq(x, y)
```

The old raw-interpolation path did not call the symbol-printing operation on nested operands, so the declarations list stayed empty. V2's recursive operand printing matches the proof.

## PO-FAMILY

For each audited composite method, the proof is the same one-step symbolic execution pattern:

1. Enter the method-specific constructor rule, such as `Lambda1(A, E)`.
2. The rule rewrites the observable string using `printStr(SI, operand)` for every SymPy operand field.
3. With `SI = true`, nested `Rat(1, 2)` rewrites to `S(1)/2`, and nested `IntExpr(1)` rewrites to `S(1)`.

Representative derivations:

- `printStr(true, Lambda1(Sym("x"), Rat(1, 2))) => "Lambda(x, S(1)/2)"`
- `printStr(true, IntervalExpr(Rat(1, 2), IntExpr(1), "")) => "Interval(S(1)/2, S(1))"`
- `printStr(true, AppliedPredicate(Pred("integer"), Rat(1, 2))) => "Q.integer(S(1)/2)"`

These claims would fail if any operand were rendered with `rawStr(...)`. The V2 diff replaces the corresponding direct operand interpolations with `self._print(...)`, so the claims align with the code.

## Frame Proof

Static diff inspection discharges the frame obligations:

- method names and signatures are unchanged;
- constructor names such as `Eq`, `Limit`, `Lambda`, `Interval`, `Normal`, and `Uniform` are unchanged;
- separators, brackets, suffix selection, and relation operator mapping are unchanged;
- no test files were modified.

The only behavioral change is that operand strings now come from the active printer.

## Residual Risk

This is a partial-correctness proof over a small abstract model, not full Python or full SymPy semantics. It is constructed, not machine-checked. Specialized `StrPrinter` delegations outside the audited operand-composition family remain unproved by this pass.

Run the commands in `fvk/PROOF_OBLIGATIONS.md` to attempt machine checking after adapting any K syntax details required by the local toolchain.
