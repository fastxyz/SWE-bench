# PROOF_OBLIGATIONS

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove` command was run.

## Machine-Check Commands To Run Later

```sh
kompile fvk/mini-python-printing.k --backend haskell
kast --backend haskell fvk/strprinter-spec.k
kprove fvk/strprinter-spec.k
```

Expected machine-check result after any K syntax repairs required by the local toolchain: all claims discharge to `#Top`.

## PO-REL - Equality-like relational operands use active printer

Public intent: `sstr(Eq(x, S(1)/2), sympy_integers=True)` must produce `Eq(x, S(1)/2)`.

Code path: `StrPrinter._print_Relational`, branch `expr.rel_op in charmap`.

Obligation:

```k
claim
  <k> printStr(true, RelExpr("==", Sym("x"), Rat(1, 2)))
   => "Eq(x, S(1)/2)" </k>
```

The proof requires both operands to be rendered by `printStr(true, ...)`, not by `rawStr(...)`.

## PO-LIMIT - Limit operands use active printer

Public intent: `sstr(Limit(x, x, S(1)/2), sympy_integers=True)` must produce `Limit(x, x, S(1)/2)`.

Code path: `StrPrinter._print_Limit`, both default direction and explicit direction branches.

Obligation:

```k
claim
  <k> printStr(true, LimitExpr(Sym("x"), Sym("x"), Rat(1, 2), "+"))
   => "Limit(x, x, S(1)/2)" </k>
```

The proof requires `e`, `z`, and `z0` to be rendered by `printStr(true, ...)`. The direction marker remains the existing raw string marker inside quotes.

## PO-PYTHON - Equality-like relationals collect nested symbols

Public intent: `python(Eq(x, y))` must produce declarations for `x` and `y`.

Code path: `PythonPrinter` dispatches to `StrPrinter._print_Relational`; symbol collection happens only through `PythonPrinter._print_Symbol`.

Obligation:

```k
claim
  <k> pythonProgram(RelExpr("==", Sym("x"), Sym("y")))
   => "x = Symbol('x')\ny = Symbol('y')\ne = Eq(x, y)" </k>
```

The proof requires recursive traversal of both operands during relational printing.

## PO-FAMILY - Other audited composite operands use active printer

Public intent: settings must be respected by nested subexpressions, and the printer infrastructure documents recursive printer use for nested expressions.

Code paths:

- `StrPrinter._print_AppliedPredicate`
- `StrPrinter._print_ExprCondPair`
- `StrPrinter._print_Interval`
- `StrPrinter._print_Lambda`
- `StrPrinter._print_MatrixElement`
- `StrPrinter._print_Normal`
- `StrPrinter._print_Uniform`

Representative obligations from `fvk/strprinter-spec.k`:

```k
claim
  <k> printStr(true, Lambda1(Sym("x"), Rat(1, 2)))
   => "Lambda(x, S(1)/2)" </k>

claim
  <k> printStr(true, IntervalExpr(Rat(1, 2), IntExpr(1), ""))
   => "Interval(S(1)/2, S(1))" </k>

claim
  <k> printStr(true, AppliedPredicate(Pred("integer"), Rat(1, 2)))
   => "Q.integer(S(1)/2)" </k>
```

The proof requires each listed method to compose its observable string from `self._print(...)` results for operand fields.

## PO-FRAME - Default shape and public APIs are preserved

Public intent: fix ignored settings without unrelated public API or string-shape changes.

Obligations:

- no method signature changes;
- no constructor names, separators, suffixes, or branch predicates changed;
- no test files changed;
- specialized domain string delegations not covered by PO-FAMILY remain outside this proof.

This is discharged by static diff inspection.
