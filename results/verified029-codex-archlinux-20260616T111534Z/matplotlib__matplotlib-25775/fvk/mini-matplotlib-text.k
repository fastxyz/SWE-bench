requires "domains.k"

module MINI-MATPLOTLIB-TEXT-SYNTAX
  imports BOOL

  syntax AAArg ::= "NoneAA" | "AA" "(" Bool ")"
  syntax Backend ::= "AggNormal" | "AggMath" | "CairoText" | "CairoMath"
                   | "CairoPathEffectCopy"

  syntax KItem ::= initText "(" AAArg "," Bool ")"
                 | setTextAA "(" AAArg "," Bool ")"
                 | drawText "(" Backend ")"
                 | drawAnnotation "(" Backend ")"
                 | parseRasterMath "(" AAArg "," Bool ")"
                 | copyCairoGC

  syntax Bool ::= resolveAA "(" AAArg "," Bool ")" [function]
endmodule

module MINI-MATPLOTLIB-TEXT
  imports MINI-MATPLOTLIB-TEXT-SYNTAX
  imports MAP

  configuration
    <k> $PGM:K </k>
    <textAA> true </textAA>
    <gcAA> true </gcAA>
    <copiedGcAA> true </copiedGcAA>
    <backendAA> .Map </backendAA>

  rule resolveAA(NoneAA, RC) => RC
  rule resolveAA(AA(B), _) => B

  rule <k> initText(ARG, RC) => . ... </k>
       <textAA> _ => resolveAA(ARG, RC) </textAA>

  rule <k> setTextAA(ARG, RC) => . ... </k>
       <textAA> _ => resolveAA(ARG, RC) </textAA>

  rule <k> drawText(BACKEND) => . ... </k>
       <textAA> TAA </textAA>
       <gcAA> _ => TAA </gcAA>
       <backendAA> OBS => OBS[BACKEND <- TAA] </backendAA>

  rule <k> drawAnnotation(BACKEND) => drawText(BACKEND) ... </k>

  rule <k> parseRasterMath(ARG, RC) => . ... </k>
       <backendAA> OBS => OBS[AggMath <- resolveAA(ARG, RC)] </backendAA>

  rule <k> copyCairoGC => . ... </k>
       <gcAA> GAA </gcAA>
       <copiedGcAA> _ => GAA </copiedGcAA>
       <backendAA> OBS => OBS[CairoPathEffectCopy <- GAA] </backendAA>
endmodule
