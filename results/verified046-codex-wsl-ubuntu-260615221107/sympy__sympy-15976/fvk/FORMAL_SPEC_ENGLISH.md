# Formal Spec In English

The K claims in `fvk/mathml-symbol-spec.k` state:

1. `SYMBOL-PLAIN`: for any base name and bold flag, if both script lists are
   empty, `printSymbol` returns exactly `MI(base, bold)`.
2. `SYMBOL-SUB`: for any base name, bold flag, and nonempty subscript list with
   no superscripts, `printSymbol` returns exactly
   `MSUB(MI(base, bold), join(subscripts))`.
3. `SYMBOL-SUP`: for any base name, bold flag, and nonempty superscript list
   with no subscripts, `printSymbol` returns exactly
   `MSUP(MI(base, bold), join(superscripts))`.
4. `SYMBOL-SUBSUP`: for any base name, bold flag, and nonempty superscript and
   subscript lists, `printSymbol` returns exactly
   `MSUBSUP(MI(base, bold), join(subscripts), join(superscripts))`.
5. `SYMBOL-X2`: given the split result for `x2`, the printed node is exactly
   `MSUB(MI("x", false), MI("2", false))`.

None of the scripted claims allows or introduces `MIWRAP` or an outer `MI`
around the script container.
