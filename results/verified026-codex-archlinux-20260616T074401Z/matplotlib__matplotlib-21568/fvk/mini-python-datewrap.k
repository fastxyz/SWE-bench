module MINI-PYTHON-DATEWRAP-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Exp ::= wrapInTex ( String )
               | dateFormatterResult ( Bool , String )

  syntax KResult ::= String
endmodule

module MINI-PYTHON-DATEWRAP
  imports MINI-PYTHON-DATEWRAP-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Spec functions model the Python regex/replace pipeline directly.
  syntax String ::= alphaTextSplit ( String ) [function]
                  | replaceDash ( String ) [function]
                  | replaceColon ( String ) [function]
                  | replaceSpace ( String ) [function]
                  | mathWrap ( String ) [function]
                  | pruneEmptyMathdefault ( String ) [function]
                  | expectedWrap ( String ) [function]

  syntax Bool ::= protectsDateSeparators ( String , String ) [function]

  rule expectedWrap(T:String)
    => pruneEmptyMathdefault(
         mathWrap(replaceSpace(replaceColon(replaceDash(alphaTextSplit(T))))))

  rule <k> wrapInTex(T:String) => expectedWrap(T) </k>
  rule <k> dateFormatterResult(true, T:String) => expectedWrap(T) </k>
  rule <k> dateFormatterResult(false, T:String) => T </k>

  rule protectsDateSeparators(T:String, expectedWrap(T)) => true [simplification]
endmodule
