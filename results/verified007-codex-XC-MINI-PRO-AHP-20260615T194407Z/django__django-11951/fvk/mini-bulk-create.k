// Constructed, not machine-checked.
// Minimal K fragment for the batching core of QuerySet._batched_insert().
// It models only the observable relevant to django__django-11951:
// the effective batch size and the list of emitted insert batch lengths.

module MINI-BULK-CREATE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax MaybeInt ::= noBatch | userBatch(Int)

  syntax Int  ::= max1(Int)                         [function]
                | minInt(Int, Int)                  [function]
                | effectiveBatch(MaybeInt, Int)     [function]
                | sumList(List)                     [function]

  syntax List ::= batchLengths(Int, Int)            [function]
  syntax Bool ::= allLeq(List, Int)                 [function]

  syntax KResult ::= Int | Bool | List | MaybeInt
endmodule

module MINI-BULK-CREATE
  imports MINI-BULK-CREATE-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:K </k>

  rule max1(C:Int) => C requires C >=Int 1
  rule max1(C:Int) => 1 requires C <Int 1

  rule minInt(A:Int, B:Int) => A requires A <=Int B
  rule minInt(A:Int, B:Int) => B requires A >Int B

  rule effectiveBatch(noBatch, C:Int) => max1(C)
  rule effectiveBatch(userBatch(U:Int), C:Int) => minInt(U, max1(C))
    requires U >Int 0

  rule batchLengths(N:Int, BS:Int) => .List
    requires N <=Int 0
  rule batchLengths(N:Int, BS:Int) => ListItem(N)
    requires N >Int 0 andBool N <=Int BS andBool BS >Int 0
  rule batchLengths(N:Int, BS:Int) => ListItem(BS) batchLengths(N -Int BS, BS)
    requires N >Int BS andBool BS >Int 0

  rule allLeq(.List, C:Int) => true
  rule allLeq(ListItem(X:Int) REST:List, C:Int) => (X <=Int C) andBool allLeq(REST, C)

  rule sumList(.List) => 0
  rule sumList(ListItem(X:Int) REST:List) => X +Int sumList(REST)
endmodule
