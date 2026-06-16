module MINI-JSONPATH-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax KeyAtom ::= numeric(Int) | text(String)
  syntax Keys ::= ".Keys" | KeyAtom Keys [right]

  syntax Component ::= member(String) | index(Int)
  syntax Components ::= ".Components" | Component Components [right]

  syntax String ::= intString(Int) [function]
  syntax Component ::= compileOne(KeyAtom) [function]
  syntax Components ::= compilePath(Keys) [function]
                      | compileFinalKeyPath(Keys) [function]
                      | hasKeyRhsPath(Keys, Bool) [function]
endmodule

module MINI-JSONPATH
  imports MINI-JSONPATH-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  rule compileOne(numeric(I:Int)) => index(I)
  rule compileOne(text(S:String)) => member(S)

  rule compilePath(.Keys) => .Components
  rule compilePath(K:KeyAtom KS:Keys) => compileOne(K) compilePath(KS)

  // Non-empty final-key compiler. Prefix components keep ordinary transform
  // semantics; only the last component is forced to object-member syntax.
  rule compileFinalKeyPath(numeric(I:Int) .Keys) => member(intString(I)) .Components
  rule compileFinalKeyPath(text(S:String) .Keys) => member(S) .Components
  rule compileFinalKeyPath(numeric(I:Int) K:KeyAtom KS:Keys)
    => index(I) compileFinalKeyPath(K KS)
  rule compileFinalKeyPath(text(S:String) K:KeyAtom KS:Keys)
    => member(S) compileFinalKeyPath(K KS)

  rule hasKeyRhsPath(KS:Keys, true) => compileFinalKeyPath(KS)
  rule hasKeyRhsPath(KS:Keys, false) => compilePath(KS)
endmodule
