module MINI-CLOSE-REQUEST-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Stmt ::= "close_request"
                | "try_close_all_finally_super"
                | "close_all"
                | "super_close_request"
                | "raise_db_error"

  syntax Outcome ::= "normal" | "dbError"
  syntax KResult ::= Int | Bool | Outcome
endmodule

module MINI-CLOSE-REQUEST
  imports MINI-CLOSE-REQUEST-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <dbOpen> 0 </dbOpen>
    <requestClosed> false </requestClosed>
    <closeAllOutcome> normal </closeAllOutcome>
    <exception> false </exception>

  rule <k> close_request => try_close_all_finally_super ... </k>

  rule <k> try_close_all_finally_super => close_all ~> super_close_request ... </k>
       <closeAllOutcome> normal </closeAllOutcome>

  rule <k> try_close_all_finally_super => close_all ~> super_close_request ~> raise_db_error ... </k>
       <closeAllOutcome> dbError </closeAllOutcome>

  rule <k> close_all => .K ... </k>
       <dbOpen> (_N:Int => 0) </dbOpen>
       <closeAllOutcome> normal </closeAllOutcome>

  rule <k> close_all => .K ... </k>
       <dbOpen> N:Int </dbOpen>
       <closeAllOutcome> dbError </closeAllOutcome>
       <exception> (_ => true) </exception>
    requires N >=Int 0

  rule <k> super_close_request => .K ... </k>
       <requestClosed> (_ => true) </requestClosed>

  rule <k> raise_db_error => .K ... </k>
       <exception> true </exception>
endmodule
