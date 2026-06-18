module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST

  syntax Val ::= "scalar" "(" Int ")"          [klabel(scalar)]
               | "point" "(" List ")"          [klabel(point)]
               | "foreign" "(" Int ")"         [klabel(foreign)]
               | "symAdd" "(" Val "," Val ")"  [klabel(symAdd)]
               | "symMul" "(" Val "," Val ")"  [klabel(symMul)]
               | "symPow" "(" Val "," Val ")"  [klabel(symPow)]
               | "foreignMul" "(" Val "," Val ")" [klabel(foreignMul)]

  syntax Expr ::= Val
                | "pointMul" "(" Val "," Val ")" [klabel(pointMul)]
                | "pointRMul" "(" Val "," Val ")" [klabel(pointRMul)]
                | "pointAdd" "(" Val "," Val ")" [klabel(pointAdd)]
                | "exprMul" "(" Val "," Val ")" [klabel(exprMul)]
                | "exprAdd" "(" Val "," Val ")" [klabel(exprAdd)]
                | "exprSub" "(" Val "," Val ")" [klabel(exprSub)]
                | "exprDiv" "(" Val "," Val ")" [klabel(exprDiv)]
                | "issueLeft" "(" Val "," Val "," Val ")" [klabel(issueLeft)]
                | "issueRight" "(" Val "," Val "," Val ")" [klabel(issueRight)]

  syntax KResult ::= Val
  syntax KItem ::= "addTo" "(" Val ")" [klabel(addTo)]
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:Expr </k>

  syntax Int ::= priority(Val) [function]
  rule priority(scalar(_)) => 10000
  rule priority(point(_)) => 10001
  rule priority(foreign(P)) => P
  rule priority(symAdd(_, _)) => 10000
  rule priority(symMul(_, _)) => 10000
  rule priority(symPow(_, _)) => 10000
  rule priority(foreignMul(_, _)) => 10000

  syntax Bool ::= isScalar(Val) [function]
                | isPoint(Val) [function]
                | isForeign(Val) [function]
  rule isScalar(scalar(_)) => true
  rule isScalar(_) => false [owise]
  rule isPoint(point(_)) => true
  rule isPoint(_) => false [owise]
  rule isForeign(foreign(_)) => true
  rule isForeign(_) => false [owise]

  syntax List ::= scale(List, Int) [function]
                | addCoords(List, List) [function]
                | negCoords(List) [function]

  rule scale(.List, _) => .List
  rule scale(ListItem(I:Int) REST:List, F:Int)
    => ListItem(I *Int F) scale(REST, F)

  rule addCoords(.List, .List) => .List
  rule addCoords(ListItem(A:Int) AS:List, ListItem(B:Int) BS:List)
    => ListItem(A +Int B) addCoords(AS, BS)

  rule negCoords(.List) => .List
  rule negCoords(ListItem(I:Int) REST:List)
    => ListItem(0 -Int I) negCoords(REST)

  rule <k> pointMul(point(CS:List), scalar(F:Int))
        => point(scale(CS, F)) ... </k>

  rule <k> pointRMul(scalar(F:Int), point(CS:List))
        => pointMul(point(CS), scalar(F)) ... </k>

  rule <k> pointAdd(point(CS1:List), point(CS2:List))
        => point(addCoords(CS1, CS2)) ... </k>

  rule <k> issueLeft(A:Val, scalar(F:Int), B:Val)
        => exprMul(scalar(F), B) ~> addTo(A) ... </k>

  rule <k> issueRight(A:Val, scalar(F:Int), B:Val)
        => pointMul(B, scalar(F)) ~> addTo(A) ... </k>

  rule <k> point(CS2:List) ~> addTo(point(CS1:List))
        => point(addCoords(CS1, CS2)) ... </k>

  rule <k> exprMul(L:Val, R:Val)
        => pointRMul(L, R) ... </k>
    requires isScalar(L) andBool isPoint(R)
     andBool priority(R) >Int priority(L)

  rule <k> exprMul(L:Val, R:Val)
        => foreignMul(L, R) ... </k>
    requires isForeign(L) andBool priority(L) >Int priority(R)

  rule <k> exprMul(L:Val, R:Val)
        => symMul(L, R) ... </k>
    requires notBool (isScalar(L) andBool isPoint(R)
      andBool priority(R) >Int priority(L))
     andBool notBool (isForeign(L) andBool priority(L) >Int priority(R))

  rule <k> exprAdd(L:Val, R:Val) => symAdd(L, R) ... </k>
  rule <k> exprSub(L:Val, point(CS:List))
        => symAdd(L, point(negCoords(CS))) ... </k>
  rule <k> exprDiv(L:Val, R:Val)
        => symMul(L, symPow(R, scalar(0 -Int 1))) ... </k>
endmodule
