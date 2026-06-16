# Formal Spec In English

This paraphrases the nontrivial K claims in `mathematica-printer-spec.k`.

## MC-MAX

For every already-constructed SymPy `Max` expression represented by class
`MaxClass`, function name `"Max"`, and argument list `ARGS`, dispatching through
the Mathematica printer terminates with output `bracketCall("Max", ARGS)`.
In concrete printer terms, this is `Max[...]`, not `Max(...)`.

## MC-MIN

For every already-constructed SymPy `Min` expression represented by class
`MinClass`, function name `"Min"`, and argument list `ARGS`, dispatching through
the Mathematica printer terminates with output `bracketCall("Min", ARGS)`.
In concrete printer terms, this is `Min[...]`, not `Min(...)`.

## MC-FUNCTION-FRAME

For every ordinary function expression represented by `FunctionClass`, dispatch
still uses bracket-call formatting with the expression's function name and
argument list. V1 does not replace or bypass the existing ordinary function path.

## MC-EXPR-FALLBACK-FRAME

For unsupported generic `ExprClass` values not covered by a more specific
printer method, dispatch still reaches the unsupported fallback and produces the
existing parenthesized representation. V1 does not globally change generic
`Expr` fallback behavior.

## Side Conditions

The claims operate on expressions after SymPy construction/evaluation. They do
not specify Python built-in `max`, SymPy `Max` construction behavior, input
source-order preservation, exact whitespace beyond the existing printer
separator, or termination beyond the straight-line dispatch rules.
