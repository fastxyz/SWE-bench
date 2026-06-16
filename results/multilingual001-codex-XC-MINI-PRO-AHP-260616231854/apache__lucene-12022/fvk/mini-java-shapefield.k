module MINI-JAVA-SHAPEFIELD-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Type ::= "POINT" | "LINE" | "TRIANGLE" | "UNKNOWN"

  // DT(aX, aY, ab, bX, bY, bc, cX, cY, ca, type)
  syntax DTri ::= "DT" "(" Int "," Int "," Bool "," Int "," Int "," Bool "," Int "," Int "," Bool "," Type ")"

  syntax Stmt ::= "resolveTriangleType"
  syntax KResult ::= DTri | Type
endmodule

module MINI-JAVA-SHAPEFIELD
  imports MINI-JAVA-SHAPEFIELD-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <tri> DT(0, 0, false, 0, 0, false, 0, 0, false, UNKNOWN) </tri>

  // Mirrors ShapeField.resolveTriangleType after V1.
  rule
    <k> resolveTriangleType => .K </k>
    <tri> DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, T)
       => DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, POINT) </tri>
    requires AX ==Int BX andBool AY ==Int BY
     andBool AX ==Int CX andBool AY ==Int CY

  rule
    <k> resolveTriangleType => .K </k>
    <tri> DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, T)
       => DT(AX, AY, BC, CX, CY, BC, AX, AY, CA, LINE) </tri>
    requires AX ==Int BX andBool AY ==Int BY
     andBool notBool (AX ==Int CX andBool AY ==Int CY)

  rule
    <k> resolveTriangleType => .K </k>
    <tri> DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, T)
       => DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, LINE) </tri>
    requires notBool (AX ==Int BX andBool AY ==Int BY)
     andBool AX ==Int CX andBool AY ==Int CY

  rule
    <k> resolveTriangleType => .K </k>
    <tri> DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, T)
       => DT(AX, AY, AB, BX, BY, BC, AX, AY, CA, LINE) </tri>
    requires notBool (AX ==Int BX andBool AY ==Int BY)
     andBool notBool (AX ==Int CX andBool AY ==Int CY)
     andBool BX ==Int CX andBool BY ==Int CY

  rule
    <k> resolveTriangleType => .K </k>
    <tri> DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, T)
       => DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, TRIANGLE) </tri>
    requires notBool (AX ==Int BX andBool AY ==Int BY)
     andBool notBool (AX ==Int CX andBool AY ==Int CY)
     andBool notBool (BX ==Int CX andBool BY ==Int CY)
endmodule
