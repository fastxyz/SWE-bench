# Formal Spec English

Status: paraphrase of the nontrivial claims in
`fvk/matrix-printing-spec.k`.

## JOIN-LOOP

For any remaining list of matrix-add terms and any accumulated output, running
the sign-joining loop appends exactly the expected rendering of the remaining
terms. The loop treats the next item as first if the first flag is true, and as
an interior item otherwise. Positive terms produce either no leading sign
(`first`) or a plus separator (`interior`). Negative terms produce either a
leading minus (`first`) or a minus separator (`interior`) and render the
positive body of the negated matrix term.

## STR-MATADD

For every non-empty in-domain `MatAdd` argument list, `StrPrinter._print_MatAdd`
returns the expected sign-joined string. In particular, the concrete issue
shape containing negative `B`, negative `A*B`, and positive `A` renders with a
leading minus for `B`, a subtraction separator for `A*B`, and a plus separator
for `A`; it does not render `(-1)*B` or `+ (-1)*A*B`.

## LATEX-MATADD

For every non-empty in-domain `MatAdd` argument list, `LatexPrinter._print_MatAdd`
returns the expected sign-joined LaTeX string. A negative matrix term's `-1`
coefficient is moved into the additive sign, so the body is printed as the
positive matrix term. A first negative LaTeX command body receives readable
spacing after the leading minus.

## PRETTY-MATADD

For every non-empty in-domain `MatAdd` argument list, `PrettyPrinter._print_MatAdd`
returns a pretty form whose additive sign sequence is the expected sign join.
Negative terms are converted to positive bodies and wrapped in a pretty form
with negative binding, so pretty addition does not insert a literal plus before
them.

## Frame Conditions

The claims do not reorder matrix-add arguments, do not alter matrix expression
construction, and do not change printer method signatures. They prove only the
sign-rendering property required by the issue.
