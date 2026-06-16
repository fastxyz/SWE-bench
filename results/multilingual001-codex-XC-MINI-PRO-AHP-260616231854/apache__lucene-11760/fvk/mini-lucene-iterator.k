module MINI-LUCENE-ITERATOR-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Action ::= "docID"
                  | "nextDoc"
                  | "advance" "(" Int ")"
  syntax Bool ::= sameDoc(Int, Int) [function]
  syntax Int ::= "NO_MORE_DOCS" [function]
  syntax KResult ::= Int | Bool
endmodule

module MINI-LUCENE-ITERATOR
  imports MINI-LUCENE-ITERATOR-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:K </k>
    <doc> -1 </doc>

  rule NO_MORE_DOCS => 2147483647

  rule <k> docID => D ... </k>
       <doc> D:Int </doc>

  rule <k> nextDoc => NO_MORE_DOCS ... </k>
       <doc> _ => NO_MORE_DOCS </doc>

  rule <k> advance(TARGET:Int) => NO_MORE_DOCS ... </k>
       <doc> _ => NO_MORE_DOCS </doc>
       requires TARGET >=Int 0

  rule sameDoc(D1:Int, D2:Int) => D1 ==Int D2
endmodule
