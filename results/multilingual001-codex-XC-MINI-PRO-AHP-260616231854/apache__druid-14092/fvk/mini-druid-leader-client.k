module MINI-DRUID-LEADER-CLIENT-SYNTAX
  imports INT-SYNTAX

  syntax StatusClass ::= "handled" | "unhandled" | "redirect"
  syntax Outcome ::= "response" "(" StatusClass ")"
                   | "transportFailure"
                   | "refreshFailure"
  syntax Result ::= "returned" "(" StatusClass ")"
                  | "retry"
                  | "throwRetriesExhausted"
  syntax KResult ::= Result

  syntax KItem ::= "goStep" "(" Int "," Outcome ")"
endmodule

module MINI-DRUID-LEADER-CLIENT
  imports MINI-DRUID-LEADER-CLIENT-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  rule <k> goStep(_C, response(handled)) => returned(handled) ... </k>
  rule <k> goStep(_C, response(redirect)) => retry ... </k>

  rule <k> goStep(C, response(unhandled)) => retry ... </k>
    requires C <Int 4

  rule <k> goStep(C, response(unhandled)) => returned(unhandled) ... </k>
    requires C >=Int 4

  rule <k> goStep(C, transportFailure) => retry ... </k>
    requires C <Int 4

  rule <k> goStep(C, transportFailure) => throwRetriesExhausted ... </k>
    requires C >=Int 4

  rule <k> goStep(_C, refreshFailure) => returned(unhandled) ... </k>
endmodule
