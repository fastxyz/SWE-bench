module MINI-HEXBIN-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax MaybeInt ::= none | some(Int)
  syntax Mode ::= countMode | cMode
  syntax KItem ::= select(Mode, MaybeInt, List)
                 | loop(Int, List, List)
  syntax KResult ::= List
endmodule

module MINI-HEXBIN
  imports MINI-HEXBIN-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:K </k>

  syntax Int ::= threshold(Mode, MaybeInt) [function]
  rule threshold(countMode, none) => 0
  rule threshold(countMode, some(M:Int)) => M
  rule threshold(cMode, none) => 1
  rule threshold(cMode, some(M:Int)) => M

  rule <k> select(MODE:Mode, MIN:MaybeInt, COUNTS:List)
        => loop(threshold(MODE, MIN), COUNTS, .List) ... </k>

  rule <k> loop(TH:Int, .List, OUT:List) => OUT ... </k>

  rule <k> loop(TH:Int, ListItem(N:Int) REST:List, OUT:List)
        => loop(TH, REST, OUT ListItem(N >=Int TH)) ... </k>
endmodule
