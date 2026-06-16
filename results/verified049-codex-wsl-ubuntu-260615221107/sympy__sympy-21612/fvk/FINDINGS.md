# FVK Findings

Status: constructed, not machine-checked. Findings are from public intent, source inspection, and formal-obligation construction only.

## F1: Legacy nested reciprocal denominator print was wrong

Classification: closed code bug.

Input: `parse_latex("\frac{a}{\frac{1}{b}}")`

Legacy observed behavior from the issue: `a/1/b`

Expected behavior from public intent: `a/(1/b)`

Cause: `_print_Mul` moved the reciprocal base into the denominator but only added explicit denominator parentheses when the base was a compound `Mul`. A nested reciprocal denominator has a `Pow` base, so it was printed without the extra grouping.

V1 status: fixed. The guard now treats `Pow` bases like `Mul` bases, so the denominator text is wrapped before composing the outer slash.

Related proof obligations: PO1, PO2, PO3.

## F2: Original nested fraction denominator is the same bug family

Classification: closed code bug.

Input: `parse_latex("\frac{\frac{a^3+b}{c}}{\frac{1}{c^2}}")`

Legacy observed behavior from the issue: `((a**3 + b)/c)/1/(c**2)`

Expected behavior from public intent: `((a**3 + b)/c)/(1/(c**2))`

Cause: the denominator `1/(c**2)` is a reciprocal whose base is a `Pow` expression. Without classifying `Pow` bases for explicit wrapping, the outer denominator grouping is lost in the string.

V1 status: fixed by the same `Pow`-base parenthesizing obligation.

Related proof obligations: PO1, PO3.

## F3: Parser changes are not justified

Classification: rejected alternative.

Input class: LaTeX fractions converted by `repo/sympy/parsing/latex/_parse_latex_antlr.py`

Observed source behavior: the parser constructs the denominator as `Pow(expr_bot, -1, evaluate=False)` and returns `Mul(expr_top, inverse_denom, evaluate=False)`.

Expected behavior: keep parser grouping and fix the printer's string rendering.

Decision: leave parser code unchanged.

Related proof obligations: PO1, PO6.

## F4: Existing `Mul`-base grouping must be preserved

Classification: frame condition, discharged.

Input: an unevaluated denominator base such as `Pow(Mul(y, y, evaluate=False), -1, evaluate=False)` inside a multiplication.

Expected behavior from existing public test evidence: denominator prints as `(y*y)`.

V1 status: preserved because the guard remains true for `Mul` and only adds `Pow` to the accepted base classes.

Related proof obligations: PO4, PO5.

## F5: Simple quotient output must remain compact

Classification: frame condition, discharged by source inspection.

Input: simple quotient shape such as `x/y`.

Expected behavior: keep `x/y`, not `x/(y)`.

V1 status: preserved. The changed guard is only reached for reciprocal `Pow` items with exponent exactly `-1`, and it only appends to `pow_paren` when the base is a compound `Mul` or `Pow` with non-singleton args.

Related proof obligations: PO5.

## F6: FVK machine proof not executed

Classification: proof capability gap.

The artifacts include `mini-str-printer.k`, `str-printer-spec.k`, and exact `kompile`/`kast`/`kprove` commands, but the task forbids running K tooling. The proof is therefore constructed, not machine-checked. This does not justify modifying tests or claiming machine-checked confidence.

Related proof obligations: PO7.
