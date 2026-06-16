# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Correct producer shape

Obligation: LaTeX fraction parsing must deliver the denominator expression to `_print_Mul` as the base of a reciprocal `Pow`, so the printer branch is the correct repair target.

Evidence: `convert_frac` in `repo/sympy/parsing/latex/_parse_latex_antlr.py` creates `inverse_denom = sympy.Pow(expr_bot, -1, evaluate=False)` and returns `sympy.Mul(expr_top, inverse_denom, evaluate=False)` when the numerator is not `1`.

Status: discharged by source inspection.

## PO2: Denominator extraction path

Obligation: In `_print_Mul`, a commutative `Pow` with negative coefficient exponent is moved into the denominator; when the exponent is exactly `-1`, the base is appended to denominator list `b`.

Evidence: the loop in `StrPrinter._print_Mul` tests `isinstance(item, Pow)` and `bool(item.exp.as_coeff_Mul()[0] < 0)`, then for `S.NegativeOne` appends `item.base` to `b`.

Status: discharged by source inspection.

## PO3: Compound `Pow` denominator bases are explicitly grouped

Obligation: If the denominator base is a compound `Pow`, the rendered denominator string must be wrapped before composing `numerator + "/" + denominator`.

V1 mechanism: `isinstance(item.base, (Mul, Pow))` adds the reciprocal item to `pow_paren`; the post-pass replaces the matching denominator string with `"(%s)" % b_str[index]`.

Formal claim: `str-printer-spec.k` proves the abstract shape `printMul(symA, reciprocal(base(powK, 2, slashText(oneText, symB)))) => slashText(symA, parenText(slashText(oneText, symB)))`.

Status: constructed proof discharged in the mini semantics; not machine-checked.

## PO4: Existing compound `Mul` denominator bases remain grouped

Obligation: The previous issue 14160 behavior must remain intact.

V1 mechanism: `Mul` remains in the accepted base classes.

Formal claim: `str-printer-spec.k` proves the abstract shape `printMul(symX, reciprocal(base(mulK, 2, yTimesY))) => slashText(symX, parenText(yTimesY))`.

Status: constructed proof discharged in the mini semantics; not machine-checked.

## PO5: Non-target denominator bases are not over-parenthesized by the new guard

Obligation: Simple denominator bases continue to print compactly.

V1 mechanism: atomic bases are not instances of `Mul` or `Pow`, and the guard also requires the base args length to be non-singleton.

Formal claim: `str-printer-spec.k` proves the abstract shape `printMul(symX, reciprocal(base(atomK, 0, symY))) => slashText(symX, symY)`.

Status: constructed proof discharged in the mini semantics; not machine-checked.

## PO6: Public compatibility

Obligation: The repair must not change public signatures, dispatch, parser APIs, or unrelated printers.

Evidence: the source diff is limited to one `isinstance` tuple inside `repo/sympy/printing/str.py`.

Status: discharged by source inspection and `PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO7: Honesty gate

Obligation: Because no tests or K tooling may be run, artifacts must label proof status as constructed, not machine-checked, and must not recommend test deletion as completed work.

Status: discharged in `PROOF.md`, `FINDINGS.md`, and `ITERATION_GUIDANCE.md`.
