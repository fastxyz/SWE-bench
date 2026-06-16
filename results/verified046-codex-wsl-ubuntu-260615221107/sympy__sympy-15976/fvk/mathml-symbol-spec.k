// Constructed, not machine-checked.
// Claims for MathMLPresentationPrinter._print_Symbol's presentation-node shape.

requires "mini-mathml.k"

module MINI-MATHML-SPEC
  imports MINI-MATHML
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: plain x works and should remain an mi token.
  // - from_tests: plain MatrixSymbol bold output is <mi mathvariant="bold">A</mi>.
  // - from_code: V1 returns mname directly when both script lists are empty.
  claim
    <k> printSymbol(BASE:String, .Strs, .Strs, BOLD:Bool)
      => MI(BASE, BOLD) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "<mi><msub>...</msub></mi>" is erroneous.
  // - from_prompt: corrected shape is "<msub><mi>r</mi><mi>2</mi></msub>".
  // - from_code: V1 returns msub directly in the subscript-only branch.
  claim
    <k> printSymbol(BASE:String, .Strs, SUB:String | SUBREST:Strs, BOLD:Bool)
      => MSUB(MI(BASE, BOLD), join(SUB | SUBREST)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the defect is the token wrapper around a presentation script.
  // - from_code: the same old wrapper mechanism also affected superscript-only
  //   symbols, so the family obligation requires returning MSUP directly.
  claim
    <k> printSymbol(BASE:String, SUP:String | SUPREST:Strs, .Strs, BOLD:Bool)
      => MSUP(MI(BASE, BOLD), join(SUP | SUPREST)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the corrected presentation shape removes the token wrapper
  //   around scripted layout nodes.
  // - from_code: V1 returns MSUBSUP directly when both script lists are present.
  claim
    <k> printSymbol(
          BASE:String,
          SUP:String | SUPREST:Strs,
          SUB:String | SUBREST:Strs,
          BOLD:Bool
        )
      => MSUBSUP(
          MI(BASE, BOLD),
          join(SUB | SUBREST),
          join(SUP | SUPREST)
        ) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: concrete issue example uses x2.
  // - from_code: split_super_sub("x2") gives base "x", subscript "2".
  claim
    <k> printSymbol("x", .Strs, "2" | .Strs, false)
      => MSUB(MI("x", false), MI("2", false)) </k>
    [all-path]
endmodule
