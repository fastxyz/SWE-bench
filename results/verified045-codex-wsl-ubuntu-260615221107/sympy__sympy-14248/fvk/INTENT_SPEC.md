# Intent Spec

Status: intent-only public specification for `sympy__sympy-14248`.

## Required Behaviors

I-001: Matrix expression subtraction must print as subtraction, not as an
addition containing an explicit `-1` coefficient. Public source: the issue
title, "The difference of MatrixSymbols prints as a sum with (-1)
coefficient."

I-002: The internal representation as a matrix sum with negative matrix-product
terms is intentional and must not be changed merely to alter display. Public
source: the issue text says differences like `a-b` are internally represented
as `a + (-1)*b`.

I-003: The three user-visible printers named by the issue must all satisfy the
subtraction-style display obligation: string printing, pretty printing, and
LaTeX printing. Public source: the issue reproducer explicitly calls `print`,
`pprint`, and `latex`.

I-004: For a negative matrix term whose matrix-product coefficient is `-1`, the
printed term body must not include the coefficient text `-1`; the minus belongs
to the surrounding addition operator. Public source: the reported bad outputs
show `(-1)*B`, `+ -A*B`, and `-1 B` as the defect.

I-005: There is no public requirement to reorder `MatAdd` arguments. The
observable obligation is sign rendering. Preserving existing argument order is
therefore a frame condition, not an independently required ordering rule.

I-006: Existing printer method signatures and the `MatAdd`/`MatMul` expression
model must remain compatible. No public API change is requested.
