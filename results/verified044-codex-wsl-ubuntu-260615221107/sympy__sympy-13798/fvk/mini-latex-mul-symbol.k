module MINI-LATEX-MUL-SYMBOL
  imports STRING
  imports BOOL

  syntax MulSymbol ::= none | str(String)

  syntax Bool ::= isLegacy(String) [function]
  rule isLegacy("ldot") => true
  rule isLegacy("dot") => true
  rule isLegacy("times") => true
  rule isLegacy(_) => false [owise]

  syntax String ::= legacySep(MulSymbol) [function]
  rule legacySep(none) => " "
  rule legacySep(str("ldot")) => " \\,.\\, "
  rule legacySep(str("dot")) => " \\cdot "
  rule legacySep(str("times")) => " \\times "

  syntax String ::= resolveMulSymbol(MulSymbol) [function]
  rule resolveMulSymbol(none) => legacySep(none)
  rule resolveMulSymbol(str(S)) => legacySep(str(S)) requires isLegacy(S)
  rule resolveMulSymbol(str(S)) => S requires notBool isLegacy(S)

  syntax String ::= resolveNumberSep(MulSymbol) [function]
  rule resolveNumberSep(none) => legacySep(str("dot"))
  rule resolveNumberSep(str(S)) => resolveMulSymbol(str(S))

  syntax String ::= join3(String, String, String, String) [function]
  rule join3(A, B, C, Sep) => A +String Sep +String B +String Sep +String C
endmodule
