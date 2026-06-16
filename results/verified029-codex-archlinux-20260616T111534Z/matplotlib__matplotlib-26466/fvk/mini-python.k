requires "domains.md"

module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX

  syntax CoordVal ::= scalar(Int)
  syntax CoordPair ::= pair(CoordVal, CoordVal)
  syntax Ref ::= arr(Int)
  syntax Stored ::= none | tup(CoordVal, CoordVal)
  syntax HeapItem ::= Ref "|->" CoordPair
  syntax Heap ::= ".Heap" | HeapItem Heap [assoc comm unit(.Heap)]

  syntax Cmd ::= storeAnnXY(Ref)
               | storeOffsetRef(Ref)
               | storeXYBox(Ref)
               | defaultXYBox
               | storeConnection(Ref, Ref)
               | mutate(Ref, Int, CoordVal)
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT

  configuration
    <k> $PGM:K </k>
    <heap> .Heap </heap>
    <annotationXY> none </annotationXY>
    <offsetRef> none </offsetRef>
    <xybox> none </xybox>
    <xy1> none </xy1>
    <xy2> none </xy2>

  // tuple(xy): read the two scalar coordinate values from the caller-owned
  // mutable object and store value cells independent from that object.
  rule <k> storeAnnXY(R) => .K </k>
       <heap> R |-> pair(X, Y) H => R |-> pair(X, Y) H </heap>
       <annotationXY> _ => tup(X, Y) </annotationXY>

  rule <k> storeOffsetRef(R) => .K </k>
       <heap> R |-> pair(X, Y) H => R |-> pair(X, Y) H </heap>
       <offsetRef> _ => tup(X, Y) </offsetRef>

  rule <k> storeXYBox(R) => .K </k>
       <heap> R |-> pair(X, Y) H => R |-> pair(X, Y) H </heap>
       <xybox> _ => tup(X, Y) </xybox>

  rule <k> defaultXYBox => .K </k>
       <annotationXY> XY </annotationXY>
       <xybox> _ => XY </xybox>

  rule <k> storeConnection(R1, R2) => .K </k>
       <heap> R1 |-> pair(X1, Y1) R2 |-> pair(X2, Y2) H
           => R1 |-> pair(X1, Y1) R2 |-> pair(X2, Y2) H </heap>
       <xy1> _ => tup(X1, Y1) </xy1>
       <xy2> _ => tup(X2, Y2) </xy2>

  // Mutating the caller object changes only the heap object.
  rule <k> mutate(R, 0, X2) => .K </k>
       <heap> R |-> pair(_, Y) H => R |-> pair(X2, Y) H </heap>

  rule <k> mutate(R, 1, Y2) => .K </k>
       <heap> R |-> pair(X, _) H => R |-> pair(X, Y2) H </heap>
endmodule
