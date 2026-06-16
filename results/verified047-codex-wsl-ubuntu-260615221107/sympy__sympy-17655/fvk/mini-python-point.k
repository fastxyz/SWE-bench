// Constructed mini-Python/SymPy fragment for Point scalar multiplication.
// This file was not kompiled or machine-checked in this environment.

module MINI-PYTHON-POINT-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  syntax Scalar ::= scalar(Int)
  syntax Coord ::= coord(Int)
                 | scaled(Coord, Scalar) [function]
                 | plusCoord(Coord, Coord) [function]
  syntax Value ::= point(List)
                 | scalarValue(Scalar)
                 | symAdd(Value, Value)
                 | symMul(Value, Value)
                 | symDiv(Value, Value)

  syntax Exp ::= Value
               | Exp "*" Exp [left, strict]
               | Exp "+" Exp [left, strict]
               | Exp "-" Exp [left, strict]
               | Exp "/" Exp [left, strict]
               | pointMul(Value, Value)
               | pointRMul(Value, Value)
               | pointRAdd(Value, Value)
               | pointRSub(Value, Value)
               | pointRDiv(Value, Value)

  syntax List ::= scale(List, Scalar) [function]
                | addCoords(List, List) [function]
                | negCoords(List) [function]
  syntax Bool ::= sameDim(List, List) [function]
endmodule

module MINI-PYTHON-POINT
  imports MINI-PYTHON-POINT-SYNTAX

  configuration <k> $PGM:Exp </k>

  // Abstract coordinate operations. scaled(C, S) represents
  // simplify(C*S) in Point.__mul__.
  rule scale(.List, S) => .List
  rule scale(ListItem(C) REST, S) => ListItem(scaled(C, S)) scale(REST, S)

  rule addCoords(.List, .List) => .List
  rule addCoords(ListItem(C1) R1, ListItem(C2) R2)
    => ListItem(plusCoord(C1, C2)) addCoords(R1, R2)

  rule negCoords(.List) => .List
  rule negCoords(ListItem(C) REST) => ListItem(scaled(C, scalar(-1))) negCoords(REST)

  rule sameDim(.List, .List) => true
  rule sameDim(ListItem(_) R1, ListItem(_) R2) => sameDim(R1, R2)
  rule sameDim(.List, ListItem(_) _) => false
  rule sameDim(ListItem(_) _, .List) => false

  // Existing Point.__mul__ behavior: point right-multiplication scales every
  // coordinate and constructs a new point.
  rule <k> point(Cs) * scalarValue(S) => pointMul(point(Cs), scalarValue(S)) ... </k>
  rule <k> pointMul(point(Cs), scalarValue(S)) => point(scale(Cs, S)) ... </k>

  // V1 behavior under Expr priority dispatch: ordinary scalar-left
  // multiplication calls Point.__rmul__, which delegates to Point.__mul__.
  rule <k> scalarValue(S) * point(Cs) => pointRMul(point(Cs), scalarValue(S)) ... </k>
  rule <k> pointRMul(point(Cs), scalarValue(S)) => point(scale(Cs, S)) ... </k>

  // Point addition after multiplication. The arithmetic details of coordinate
  // addition are abstracted; the observable is that the right operand is a
  // point, not a symbolic Mul containing a point.
  rule <k> point(Ps) + point(Qs) => point(addCoords(Ps, Qs)) ... </k>
    requires sameDim(Ps, Qs)

  // Frame rules for Expr-left operations considered because Point now has
  // priority. These preserve the prior symbolic construction behavior.
  rule <k> scalarValue(S) + point(Cs) => pointRAdd(point(Cs), scalarValue(S)) ... </k>
  rule <k> pointRAdd(point(Cs), scalarValue(S)) => symAdd(scalarValue(S), point(Cs)) ... </k>

  rule <k> scalarValue(S) - point(Cs) => pointRSub(point(Cs), scalarValue(S)) ... </k>
  rule <k> pointRSub(point(Cs), scalarValue(S)) => symAdd(scalarValue(S), point(negCoords(Cs))) ... </k>

  rule <k> scalarValue(S) / point(Cs) => pointRDiv(point(Cs), scalarValue(S)) ... </k>
  rule <k> pointRDiv(point(Cs), scalarValue(S)) => symDiv(scalarValue(S), point(Cs)) ... </k>
endmodule
