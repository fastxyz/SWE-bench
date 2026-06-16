# Public Evidence Ledger

## E-001

Source: prompt / issue title.

Quoted evidence: "The difference of MatrixSymbols prints as a sum with (-1)
coefficient."

Semantic obligation: negative matrix terms in a printed `MatAdd` must be
rendered by subtraction syntax rather than by exposing a `-1` scalar factor.

Status: encoded by `SPEC.md`, `matrix-printing-spec.k`, and proof obligations
`PO-SIGN`, `PO-STR`, `PO-LATEX`, and `PO-PRETTY`.

## E-002

Source: prompt / issue body.

Quoted evidence: "Internally, differences like a-b are represented as the sum
of a with `(-1)*b`, but they are supposed to print like a-b."

Semantic obligation: keep the internal representation as an implementation
fact, but make the printer observe the negative coefficient and choose a minus
separator.

Status: encoded as a frame condition in `SPEC.md`; checked by `PO-FRAME-REP`.

## E-003

Source: prompt / reproducer.

Quoted evidence: the issue calls `print(A - A*B - B)`,
`pprint(A - A*B - B)`, and `latex(A - A*B - B)`.

Semantic obligation: the string, pretty, and LaTeX matrix-add printers are all
in scope.

Status: encoded by `PO-COVERAGE`; all three `_print_MatAdd` methods changed in
V1.

## E-004

Source: prompt / reported outputs.

Quoted evidence: `(-1)*B + (-1)*A*B + A`, `-B + -A*B + A`, and
`'-1 B + -1 A B + A'`.

Semantic obligation: a correct output must not have a literal plus before a
negative matrix term and must not show a unit negative coefficient as the
matrix term's body.

Status: encoded by `PO-NO-PLUS-NEG` and `PO-NO-UNIT-COEFF`.

## E-005

Source: code, `repo/sympy/matrices/expressions/matmul.py`.

Evidence: `MatMul.as_coeff_mmul()` returns the scalar coefficient and the
matrix-product portion.

Semantic role: implementation evidence for how a printer can detect the sign
without changing expression semantics.

Status: encoded by `PO-SIGN`.

## E-006

Source: code, `repo/sympy/matrices/expressions/matexpr.py`.

Evidence: base `MatrixExpr.as_coeff_mmul()` returns a positive coefficient for
plain matrix expressions.

Semantic role: implementation evidence that positive matrix terms remain
positive under the V1 sign classifier.

Status: encoded by `PO-SIGN` and `PO-FRAME-POSITIVE`.
