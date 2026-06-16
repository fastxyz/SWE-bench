# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## What Is Proved

For every non-empty in-domain `MatAdd` argument list, the V1 implementations of
`StrPrinter._print_MatAdd`, `LatexPrinter._print_MatAdd`, and
`PrettyPrinter._print_MatAdd` render matrix terms with scalar coefficients that
extract a minus sign as subtraction in the surrounding matrix-add expression.
The proof is partial correctness: if the printer method returns, the sign
sequence of the output satisfies the specification. Termination is evident from
iteration over finite `expr.args`, but no machine-checked termination proof is
claimed.

## Formal Core

`fvk/mini-python.k` defines an abstract sign-joining semantics for a printer
loop over matrix-add terms. A term is abstracted to either `pos(B)` or `neg(B)`,
where `B` is the positive body printed after any sign stripping.

`fvk/matrix-printing-spec.k` defines `expected(Terms, First)` and four claims:

- `JOIN-LOOP`: processing a suffix appends exactly the expected signed pieces.
- `STR-MATADD`: `render(str, TS)` yields `expected(TS, true)`.
- `LATEX-MATADD`: `render(latex, TS)` yields `expected(TS, true)`.
- `PRETTY-MATADD`: `render(pretty, TS)` yields `expected(TS, true)`.

## Proof Sketch

The proof obligation is a list-iteration invariant.

Base case: the remaining term list is empty. The loop stops and the output cell
is the accumulator. Since `expected(.Terms, First) = .Pieces`, the accumulator
equals `ACC ++ expected(.Terms, First)`.

Inductive step, first positive term: the loop appends `bare(B)`, clears the
first flag, and recurs on the suffix. By the induction hypothesis, the final
output is `ACC ++ bare(B) ++ expected(TS, false)`, which equals
`ACC ++ expected(pos(B); TS, true)`.

Inductive step, interior positive term: the loop appends `plus(B)`, keeps the
first flag false, and recurs. The final output equals
`ACC ++ expected(pos(B); TS, false)`.

Inductive step, first negative term: the V1 code detects the extractable minus
coefficient, replaces the term body by the rendering of `-term`, appends a
leading-minus piece, clears the first flag, and recurs. The final output equals
`ACC ++ expected(neg(B); TS, true)`.

Inductive step, interior negative term: the V1 code detects the extractable
minus coefficient, replaces the term body by the rendering of `-term`, appends
a subtraction piece, and recurs. The final output equals
`ACC ++ expected(neg(B); TS, false)`.

By transitivity over the finite loop and the four cases above, `JOIN-LOOP`
holds for every finite suffix. Instantiating the loop with an empty accumulator
and `First = true` gives the three printer-entry claims.

For the concrete issue shape `neg(B); neg(AB); pos(A); .Terms`, the expected
piece sequence is `firstMinus(B); minus(AB); plus(A); .Pieces`. This forbids
both explicit unit negative coefficient body text and a literal plus before the
second negative term.

## Mapping Back to V1 Source

`PO-SIGN` maps `neg(B)` to the branch where
`S(coeff).could_extract_minus_sign()` is true. The positive body `B` corresponds
to rendering `-term`.

`PO-STR` maps the abstract pieces to `parts.extend([sign, body])`, then the
first sign pop and leading plus erasure in `repo/sympy/printing/str.py`.

`PO-LATEX` maps the abstract pieces to direct string accumulation in
`repo/sympy/printing/latex.py`.

`PO-PRETTY` maps the abstract negative pieces to `pretty_negative(...)` with
`prettyForm.NEG` binding in `repo/sympy/printing/pretty/pretty.py`.

## Machine-Check Commands Not Run

The commands that would machine-check the constructed proof are:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/matrix-printing-spec.k
kprove fvk/matrix-printing-spec.k
```

Expected successful outcome: `kprove` discharges the claims to `#Top`.

## Test Guidance

No tests were modified. If tests are added later, they should cover:

- string rendering of `A - A*B - B`;
- pretty rendering of the same expression, checking that no literal plus
  precedes the negative `A*B` term;
- LaTeX rendering of the same expression, checking that unit negative
  coefficients are not printed as `-1` term bodies;
- a positive-first, negative-interior matrix sum to exercise the interior
  subtraction branch directly.

After actual machine checking, point tests fully entailed by the claims may be
considered redundant, but test removal remains recommendation-only and is not
part of this task.
