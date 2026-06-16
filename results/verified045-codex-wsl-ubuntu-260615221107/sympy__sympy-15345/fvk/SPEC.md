# SPEC

Constructed, not machine-checked.

## Scope

Target: `repo/sympy/printing/mathematica.py`, specifically
`MCodePrinter` dispatch for SymPy `Max` and `Min` expressions.

The specified observable is the string emitted by `mathematica_code(expr)` after
SymPy has already constructed/evaluated `expr`. The spec does not cover Python
built-in `max`, construction-time simplification of `Max`/`Min`, or source-order
preservation before SymPy canonicalization.

## Contract

For every in-domain SymPy `Max` expression that reaches `MCodePrinter`, the
printer must emit a Mathematica function call with square brackets:

`Max[<printed expr.args>]`

For every in-domain SymPy `Min` expression that reaches `MCodePrinter`, the
printer must emit:

`Min[<printed expr.args>]`

The normal Mathematica printer separator is retained. Existing public tests use
a comma followed by a space, so an expression with canonical arguments `(2, x)`
is specified as the shape `Max[2, x]`, not as the invalid `Max(2, x)`.

## Frame Conditions

Ordinary `Function` printing remains bracket-based, as in existing public tests:
`f[x, y, z]`, `Sin[x]`, and `Conjugate[x]`.

Unsupported generic expressions remain on the existing fallback path. The fix is
not a global replacement of `CodePrinter._print_Expr` or `StrPrinter.emptyPrinter`.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "`mathematica_code(Max(x,2))` ... expect ... `'Max[x,2]'`" | A SymPy `Max` expression must render with Mathematica square brackets. | MC-MAX |
| E2 | prompt | "`'Max(2, x)'` ... is not valid Mathematica code" | Parenthesis-call fallback is a bug for `Max`. | Finding F1, MC-MAX |
| E3 | prompt hint | "neither Mathematica `Max` or `Min` functions are in" | Include `Min` as the same homogeneous printer family. | MC-MIN |
| E4 | prompt hint | "`max` (lowercase `m`) is the Python builtin" | Lowercase `max` is outside the repair domain. | Scope |
| E5 | public test | `test_Function` expects bracket syntax for ordinary functions. | Preserve existing function bracket printing. | MC-FUNCTION-FRAME |
| E6 | source | `MCodePrinter._print_Function` emits `"%s[%s]"`. | Delegating `Max`/`Min` to this method achieves the bracket syntax. | PO1, PO2 |
| E7 | source | inherited `CodePrinter._print_Expr` reaches unsupported fallback. | Explains the pre-fix parenthesized output. | Finding F1 |
| E8 | source | `MinMaxBase` canonicalizes argument storage. | Output order is `expr.args`, not original source text order. | Scope |

## Formal Claims

The K-style formal core is in:

- `fvk/mini-python-printer.k`
- `fvk/mathematica-printer-spec.k`

Claims:

- MC-MAX: `MaxClass` dispatch reaches `bracketCall("Max", ARGS)`.
- MC-MIN: `MinClass` dispatch reaches `bracketCall("Min", ARGS)`.
- MC-FUNCTION-FRAME: ordinary `FunctionClass` dispatch remains bracket-based.
- MC-EXPR-FALLBACK-FRAME: generic unsupported `ExprClass` fallback remains
  parenthesis/repr-based.

The model is intentionally minimal but property-complete for this issue: it
represents the discriminating observable, bracket-call versus parenthesis-call
formatting, and the dispatch distinction V1 changed.
