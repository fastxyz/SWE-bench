# Formal Spec English

Status: constructed, not machine-checked.

## Claim paraphrases

`PAREN-LOW-STRICT`

For any modeled expression whose precedence is lower than `Mul`, strict
parenthesizing at level `Mul` returns the rendered expression wrapped in
parentheses.

`PAREN-NONLOW-STRICT`

For any modeled expression whose precedence is not lower than `Mul`, strict
parenthesizing at level `Mul` returns the rendered expression unchanged.

`SUBS-LOW-PRECEDENCE`

For any modeled additive `Subs` expression, `_print_Subs` renders the expression
before the evaluation bar with parentheses and leaves the substitution
assignment suffix unchanged.

`SUBS-NONLOW-PRECEDENCE`

For any modeled non-additive `Subs` expression, `_print_Subs` renders the
expression before the evaluation bar without adding parentheses and leaves the
substitution assignment suffix unchanged.

`ISSUE-EXAMPLE`

For the modeled issue input `3*Subs(-x+y, (x,), (1,))`, the result has a numeric
coefficient followed by a `Subs` rendering whose inner additive expression is
parenthesized.

`LEGACY-COUNTEREXAMPLE-DIAGNOSTIC`

The legacy direct-rendering mechanism produces the reported bad shape: the
numeric coefficient is followed by a `Subs` rendering whose inner additive
expression is raw, not parenthesized. This claim is diagnostic and is not a
contract for the V1 candidate.

## Frame conditions

The claims preserve the assignment suffix `A`. The V1 change affects only the
expression rendered before the substitution bar.

The claims preserve non-additive expression rendering for the modeled
multiplicative, derivative-precedence, and atomic expression classes.

## Side conditions

The only proof side conditions are precedence comparisons against the
multiplicative level `50`. They are backed by the modeled values
`prec(addExpr) = 40`, `prec(mulExpr) = 50`, `prec(derivativeExpr) = 50`, and
`prec(atomExpr) = 1000`.
