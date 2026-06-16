module MINI-JAVA-CACHE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Stmt ::= restorePostAggs(Int, Int)
                | loopPostAggs(Int, Int)

  syntax KResult ::= Int | Bool | List
endmodule

module MINI-JAVA-CACHE
  imports MINI-JAVA-CACHE-SYNTAX
  imports INT
  imports BOOL
  imports LIST
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <postPos> 0 </postPos>
    <results> .List </results>
    <row> .Map </row>

  rule <k> restorePostAggs(P:Int, START:Int) => loopPostAggs(P, START) ... </k>

  rule <k> loopPostAggs(P:Int, START:Int) => loopPostAggs(P, START) ... </k>
       <postPos> I:Int => I +Int 1 </postPos>
       <results> ListItem(V) REST => REST </results>
       <row> ROW:Map => ROW [ START +Int I <- V ] </row>
    requires I <Int P

  rule <k> loopPostAggs(P:Int, START:Int) => .K ... </k>
       <postPos> I:Int </postPos>
    requires I >=Int P
endmodule
