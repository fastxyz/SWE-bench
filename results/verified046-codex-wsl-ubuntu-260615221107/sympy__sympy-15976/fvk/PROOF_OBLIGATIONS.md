# Proof Obligations

Status: constructed, not machine-checked.

## PO-SPLIT-X2

For `split_super_sub("x2")`, the result is base `x`, empty superscripts, and
subscripts containing exactly `2`. This follows by static inspection of
`_name_with_digits_p = r'^([a-zA-Z]+)([0-9]+)$'` and the `subs.insert(0, sub)`
branch.

## PO-PLAIN-FRAME

For any symbol whose split result has no superscripts and no subscripts,
`_print_Symbol` returns a top-level `mi` containing the translated base name.
This preserves the public behavior for `Symbol("x")` and Greek-name translation.

## PO-BOLD-FRAME

For `style == 'bold'`, the returned base `mi` carries `mathvariant="bold"`.
For a plain matrix symbol this preserves the exact existing output
`<mi mathvariant="bold">A</mi>`.

## PO-JOIN-SCRIPTS

For a one-element script list, `join(items)` returns a single `mi`. For a
multi-element script list, it returns `mrow` with script `mi` nodes separated by
space `mo` nodes. This is unchanged from the pre-V1 implementation.

## PO-SUB-NO-OUTER-MI

If `subs` is nonempty and `supers` is empty, `_print_Symbol` returns
`msub(base_mi, join(subs))` directly. The returned top-level node is not `mi`.

## PO-SUP-NO-OUTER-MI

If `supers` is nonempty and `subs` is empty, `_print_Symbol` returns
`msup(base_mi, join(supers))` directly. The returned top-level node is not `mi`.

## PO-SUBSUP-NO-OUTER-MI

If both `subs` and `supers` are nonempty, `_print_Symbol` returns
`msubsup(base_mi, join(subs), join(supers))` directly. The returned top-level
node is not `mi`.

## PO-ISSUE-EXPR

For the issue expression `x2*z + x2**3`, every occurrence of `_print_Symbol(x2)`
has the shape required by `PO-SUB-NO-OUTER-MI`. `_print_Mul` appends that node
directly into an `mrow`, and `_print_Pow` appends it inside `mfenced` for a
multi-character base; neither contributor adds an outer `mi` around it.

## PO-CONTENT-FRAME

The content MathML symbol printer remains unchanged. This is compatible with the
intent because the reported bug and corrected markup are presentation MathML.

## PO-ADEQUACY-LEGACY-TEST-CONFLICT

Any claim that scripted presentation symbols must have top-level `mi` is rejected
as legacy-derived because it conflicts with the issue's positive corrected
markup. Therefore a proof of V1 need not preserve that old DOM shape.

## PO-PUBLIC-API-FRAME

The V1 fix does not change public function names, method signatures, setting
names, or the dispatch path from `mathml(expr, printer='presentation')` to
`MathMLPresentationPrinter.doprint(expr)`.
