# Intent-Only Specification

This file intentionally ignores V1 behavior except as something to audit.

1. Presentation MathML for symbols whose names imply subscripts must not wrap a
   scripted layout node inside an outer `mi` token.
2. A symbol ending in digits, such as `x2`, remains a subscripted symbol, not
   literal text `x2`, because SymPy's printer convention treats trailing digits
   as subscripts.
3. The corrected shape for `x2` is
   `<msub><mi>x</mi><mi>2</mi></msub>`.
4. The full expression `x2*z + x2**3` must not contain the old
   `<mi><msub>...` shape anywhere presentation symbol printing contributes.
5. Plain presentation symbols such as `x` remain `<mi>x</mi>`.
6. Public API surface and settings such as `mathml(..., printer='presentation')`
   and `mat_symbol_style` remain compatible.
7. Content MathML behavior is not part of this bug because the issue path uses
   the presentation printer.
