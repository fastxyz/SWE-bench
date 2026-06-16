module MINI-SYMPY-POINT-SYNTAX
  imports BOOL-SYNTAX

  syntax Coord ::= realNum
                 | residualZeroNum
                 | complexNum
                 | symbolicCoord

  syntax Coords ::= ".Coords"
                  | Coord ";" Coords [right]

  syntax Outcome ::= ok | imaginaryError

  syntax KItem ::= validate(Coords)
                 | validateEval(Coords, Bool)
endmodule

module MINI-SYMPY-POINT
  imports MINI-SYMPY-POINT-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:K </k>
    <eval> true </eval>
    <out> ok </out>

  syntax Bool ::= isNumber(Coord) [function]
  rule isNumber(realNum) => true
  rule isNumber(residualZeroNum) => true
  rule isNumber(complexNum) => true
  rule isNumber(symbolicCoord) => false

  syntax Bool ::= imagTruthy(Coord, Bool) [function]
  rule imagTruthy(realNum, _) => false
  rule imagTruthy(residualZeroNum, true) => false
  rule imagTruthy(residualZeroNum, false) => true
  rule imagTruthy(complexNum, _) => true
  rule imagTruthy(symbolicCoord, _) => false

  syntax Bool ::= badCoord(Coord) [function]
  rule badCoord(C) => isNumber(C) andBool imagTruthy(C, true)

  syntax Bool ::= anyBad(Coords) [function]
  rule anyBad(.Coords) => false
  rule anyBad(C ; CS) => badCoord(C) orBool anyBad(CS)

  // Model: with evaluate_context(True): run the validation walk, then restore.
  rule <k> validate(CS) => validateEval(CS, OLD) ... </k>
       <eval> OLD => true </eval>

  rule <k> validateEval(.Coords, OLD) => .K ... </k>
       <eval> _ => OLD </eval>
       <out> _ => ok </out>

  rule <k> validateEval(C ; CS, OLD) => .K ... </k>
       <eval> _ => OLD </eval>
       <out> _ => imaginaryError </out>
    requires badCoord(C)

  rule <k> validateEval(C ; CS, OLD) => validateEval(CS, OLD) ... </k>
    requires notBool badCoord(C)
endmodule
