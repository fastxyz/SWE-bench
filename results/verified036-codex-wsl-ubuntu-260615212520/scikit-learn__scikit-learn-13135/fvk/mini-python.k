module MINI-PYTHON-KBINS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax KItem ::= sortCenters(List)
                 | kmeansEdges(Int, Int, List)
                 | digitizeWithBins(List)

  syntax KResult ::= List | Bool
endmodule

module MINI-PYTHON-KBINS
  imports MINI-PYTHON-KBINS-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:K </k>

  syntax List ::= sortInts(List) [function]
  syntax List ::= edgesFromSortedCenters(Int, Int, List) [function]
  syntax List ::= mids(List) [function]
  syntax List ::= tail(List) [function]

  syntax Bool ::= sorted(List) [function]
  syntax Bool ::= inRange(Int, Int, List) [function]
  syntax Bool ::= sameBag(List, List) [function]

  syntax Int ::= mid(Int, Int) [function]
  syntax Int ::= length(List) [function]

  rule <k> sortCenters(CS:List) => sortInts(CS) ... </k>

  rule <k> kmeansEdges(MIN:Int, MAX:Int, CS:List)
        => edgesFromSortedCenters(MIN, MAX, sortInts(CS)) ... </k>

  rule <k> digitizeWithBins(BINS:List) => true ... </k>
    requires sorted(BINS)

  rule mid(A:Int, B:Int) => (A +Int B) /Int 2

  rule edgesFromSortedCenters(MIN:Int, MAX:Int, CS:List)
    => ListItem(MIN) mids(CS) ListItem(MAX)

  rule mids(.List) => .List
  rule mids(ListItem(C:Int)) => .List
  rule mids(ListItem(A:Int) ListItem(B:Int) REST:List)
    => ListItem(mid(A, B)) mids(ListItem(B) REST)

  rule tail(.List) => .List
  rule tail(ListItem(C:Int) REST:List) => REST

  rule length(.List) => 0
  rule length(ListItem(C:Int) REST:List) => 1 +Int length(REST)

  rule sorted(.List) => true
  rule sorted(ListItem(C:Int)) => true
  rule sorted(ListItem(A:Int) ListItem(B:Int) REST:List)
    => (A <=Int B) andBool sorted(ListItem(B) REST)

  rule inRange(MIN:Int, MAX:Int, .List) => true
  rule inRange(MIN:Int, MAX:Int, ListItem(C:Int) REST:List)
    => ((MIN <=Int C) andBool (C <=Int MAX)) andBool inRange(MIN, MAX, REST)

  // Abstract laws for the modeled np.sort operation.
  rule sorted(sortInts(CS:List)) => true [simplification]
  rule sameBag(CS:List, sortInts(CS)) => true [simplification]
  rule inRange(MIN:Int, MAX:Int, sortInts(CS:List))
    => inRange(MIN, MAX, CS) [simplification]

  // Midpoint-edge monotonicity lemma used by the constructed proof.
  rule sorted(edgesFromSortedCenters(MIN:Int, MAX:Int, CS:List)) => true
    requires (MIN <Int MAX)
     andBool sorted(CS)
     andBool inRange(MIN, MAX, CS)
     andBool (length(CS) >=Int 2)
    [simplification]

  rule sorted(tail(BINS:List)) => true
    requires sorted(BINS)
    [simplification]
endmodule
