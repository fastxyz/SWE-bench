# Intent Spec

Status: constructed from public issue text and source inspection; no execution performed.

## Required behavior

1. A LaTeX fraction whose denominator is itself a fraction must print with denominator grouping preserved. The simplified representative is `\frac{a}{\frac{1}{b}}`, whose displayed string must be `a/(1/b)`, not `a/1/b`.
2. The original representative `\frac{\frac{a^3+b}{c}}{\frac{1}{c^2}}` must preserve the outer denominator as `1/(c**2)`, yielding a grouped denominator in the string form.
3. Existing denominator grouping for compound `Mul` bases must remain intact. The public source test near issue 14160 expects an unevaluated denominator base `y*y` to print as `x/(y*y)` rather than `x/y*y`.
4. Simple denominator bases must retain the existing compact form, such as `x/y`.
5. The LaTeX parser is not required to change if the expression tree is already correct; the bug is in the string printer's observable output.

## Domain

The FVK target is the `_print_Mul` denominator path for commutative `Pow` factors whose exponent is exactly `-1`, because the parser creates fractions as `Mul(numerator, Pow(denominator, -1, evaluate=False), evaluate=False)`. Within that path, the in-domain denominator base classes relevant to the issue are `Mul`, `Pow`, and non-compound bases.

## Frame conditions

1. Do not change parser construction of fraction expressions.
2. Do not change public APIs, signatures, return types, or test files.
3. Do not change unrelated printers.
4. Preserve existing `Mul`-base parenthesizing behavior while adding the missing `Pow`-base case.
