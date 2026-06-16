requires "mini-latex-mul-symbol.k"

module LATEX-MUL-SYMBOL-SPEC
  imports MINI-LATEX-MUL-SYMBOL

  // SPEC-PROVENANCE:
  // - from_prompt: "mul_symbol kwarg ... must be one of four choices" and
  //   "I would like to be able to supply my own choice" => non-legacy strings
  //   are in-domain.
  // - from_hint: "an unknown argument is used as the latex" => custom strings
  //   are used directly as the separator.
  claim resolveMulSymbol(str(S)) => S
    requires notBool isLegacy(S)

  // SPEC-PROVENANCE:
  // - from_prompt: "backwards-compatible" => old aliases keep old separators.
  claim resolveMulSymbol(none) => " "
  claim resolveMulSymbol(str("ldot")) => " \\,.\\, "
  claim resolveMulSymbol(str("dot")) => " \\cdot "
  claim resolveMulSymbol(str("times")) => " \\times "

  // SPEC-PROVENANCE:
  // - from_code_comment: Float scientific notation must always use a visible
  //   multiplication separator when the public setting is the default None.
  // - from_prompt: custom separator should be the user's choice otherwise.
  claim resolveNumberSep(none) => " \\cdot "
  claim resolveNumberSep(str(S)) => resolveMulSymbol(str(S))

  // SPEC-PROVENANCE:
  // - from_prompt: thin-space example over 3*x**2*y.
  // - from_hint: custom string is used as latex, so r"\," is a complete
  //   separator and is not automatically padded with ASCII spaces.
  claim join3("3", "x^{2}", "y", resolveMulSymbol(str("\\,")))
    => "3\\,x^{2}\\,y"
endmodule
