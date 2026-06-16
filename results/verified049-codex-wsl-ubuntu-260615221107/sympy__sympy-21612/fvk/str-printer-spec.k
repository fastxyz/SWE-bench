requires "mini-str-printer.k"

module STR-PRINTER-SPEC
  imports MINI-STR-PRINTER

  // SPEC-PROVENANCE:
  // - from_prompt: simplified failure `\frac{a}{\frac{1}{b}}` printed as `a/1/b`
  // - obligation: a compound Pow denominator base must be grouped as `a/(1/b)`
  // - from_code: V1 classifies item.base as `(Mul, Pow)` before b_str wrapping
  claim
    <k> printMul(symA, reciprocal(base(powK, 2, slashText(oneText, symB))))
      => slashText(symA, parenText(slashText(oneText, symB))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: original expression has outer denominator `1/(c**2)`
  // - obligation: a Pow-shaped denominator base remains one grouped denominator
  claim
    <k> printMul(fracNumer, reciprocal(base(powK, 2, slashText(oneText, cSquared))))
      => slashText(fracNumer, parenText(slashText(oneText, cSquared))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: issue 14160 expects `-2*x/(y*y)` for a Mul denominator base
  // - obligation: V1 must preserve existing Mul-base grouping behavior
  claim
    <k> printMul(symX, reciprocal(base(mulK, 2, yTimesY)))
      => slashText(symX, parenText(yTimesY)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: simple quotient examples expect compact denominator output
  // - obligation: atomic denominator bases are not newly wrapped
  claim
    <k> printMul(symX, reciprocal(base(atomK, 0, symY)))
      => slashText(symX, symY) </k>
    [all-path]
endmodule
