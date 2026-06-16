# FVK Spec

Status: constructed, not machine-checked. No tests, Python execution, or K
tooling were run.

## Target

The audited units are:

- `repo/sympy/printing/str.py`: `StrPrinter._print_MatAdd`
- `repo/sympy/printing/latex.py`: `LatexPrinter._print_MatAdd`
- `repo/sympy/printing/pretty/pretty.py`: `PrettyPrinter._print_MatAdd`

The intended observable is the rendered matrix-addition output for a non-empty
`MatAdd` term list.

## Domain

The in-domain input is a non-empty `MatAdd` whose arguments are printable
matrix terms. Terms may be plain matrix expressions, matrix products with a
scalar coefficient, or explicit matrix-like objects that do not expose
`as_coeff_mmul()`. For objects without `as_coeff_mmul()`, the existing printer
path is preserved and the term is treated as not having an extractable matrix
coefficient.

`MatAdd` with no arguments is out of scope: the constructor validates shape by
looking at `args[0]`, so an empty matrix-add expression is not an intended
public printer input.

## Public Intent Ledger

This section mirrors the standalone ledger in
`fvk/PUBLIC_EVIDENCE_LEDGER.md`.

- E-001: the issue title identifies explicit `(-1)` matrix coefficients in
  printed differences as the defect.
- E-002: the issue says the internal representation as `a + (-1)*b` is normal,
  so the fix belongs in printing rather than expression construction.
- E-003: the issue exercises `print`, `pprint`, and `latex`, so all three
  corresponding matrix-add printers are in scope.
- E-004: the reported bad outputs identify two forbidden output shapes:
  literal plus before a negative term and visible unit negative coefficient in
  a matrix term body.
- E-005: `MatMul.as_coeff_mmul()` provides the scalar coefficient needed for
  matrix-specific sign classification.
- E-006: base `MatrixExpr.as_coeff_mmul()` reports a positive coefficient for
  plain matrix expressions, preserving positive terms.

## Formal Model

The K model in `fvk/mini-python.k` abstracts each matrix-add argument to:

- `pos(B)`: a term whose matrix coefficient does not extract a minus sign;
- `neg(B)`: a term whose matrix coefficient does extract a minus sign;
- `B`: the rendered body of the positive term after any needed negation.

The model intentionally abstracts away the detailed rendering of a positive
matrix product (`A*B` vs `A B` vs pretty multiplication), because the defect is
the surrounding additive sign discipline. The abstraction is property-complete:
it distinguishes a passing render such as `B ; minus(AB) ; plus(A)` from a
failing render that places a plus separator before the negative `AB` term.

For any term list `t0, ..., tn`, define `ExpectedJoin`:

- If `ti` is positive and `i == 0`, emit the term body with no leading plus.
- If `ti` is positive and `i > 0`, emit a plus separator followed by the term
  body.
- If `ti` is negative and `i == 0`, emit a leading minus followed by the body
  of `-ti`.
- If `ti` is negative and `i > 0`, emit a minus separator followed by the body
  of `-ti`.

The string and LaTeX printers realize this directly as text assembly. The
pretty printer realizes the same sign sequence by assigning negative
`prettyForm` binding to negative terms so `prettyForm.__add__` does not insert a
literal plus before them.

## Frame Conditions

F-ORD: The order of `expr.args` is preserved. The public issue requires
subtraction-style rendering, not a new ordering rule.

F-REP: `MatAdd`, `MatMul`, `MatrixExpr`, and `MatrixSymbol` construction and
canonicalization are unchanged.

F-API: `_print_MatAdd` method signatures are unchanged. Existing callers and
direct uses of those methods remain compatible.

F-PAREN: The string printer continues to use `parenthesize(arg, precedence(expr))`
for matrix-add arguments after sign stripping, preserving the existing
parenthesization discipline for the positive body.

## Claims

The formal claims are in `fvk/matrix-printing-spec.k`.

- `STR-MATADD`: string matrix addition emits `ExpectedJoin`.
- `LATEX-MATADD`: LaTeX matrix addition emits `ExpectedJoin`, with the same
  sign sequence and style-specific body rendering abstracted behind `B`.
- `PRETTY-MATADD`: pretty matrix addition emits `ExpectedJoin`, where negative
  pieces are represented by negative binding instead of plus-separated positive
  pieces.
- `JOIN-LOOP`: the shared loop invariant: after any processed prefix, the
  accumulated output equals `ExpectedJoin(prefix)` and processing the suffix
  appends exactly `ExpectedJoin(suffix)` under the correct first/interior flag.
