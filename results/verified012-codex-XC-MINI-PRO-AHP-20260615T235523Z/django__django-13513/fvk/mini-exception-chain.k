module MINI-EXCEPTION-CHAIN-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX
  imports LIST-SYNTAX

  syntax Cause ::= "none"
                 | "exc" "(" Int ")"

  syntax Exp ::= Cause
               | Bool
               | "resolve" "(" Cause "," Bool "," Cause ")"
               | "isExplicit" "(" Cause ")"
               | "collect" "(" Cause "," Int ")"

  syntax KItem ::= "continueCollect" "(" Cause "," Int ")"

  syntax KResult ::= Cause | Bool
endmodule

module MINI-EXCEPTION-CHAIN
  imports MINI-EXCEPTION-CHAIN-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST

  configuration
    <k> $PGM:Exp </k>
    <explicit> .Map </explicit>
    <suppress> .Map </suppress>
    <context> .Map </context>
    <seen> .List </seen>

  rule <k> resolve(C:Cause, _:Bool, _:Cause) => C ... </k>
    requires C =/=K none

  rule <k> resolve(none, true, _:Cause) => none ... </k>
  rule <k> resolve(none, false, I:Cause) => I ... </k>

  rule <k> isExplicit(none) => false ... </k>
  rule <k> isExplicit(C:Cause) => true ... </k>
    requires C =/=K none

  rule <k> collect(none, _:Int) => .K ... </k>

  rule <k> collect(E:Cause, F:Int) => .K ... </k>
    requires E =/=K none andBool F <=Int 0

  rule <k> collect(E:Cause, F:Int) => resolve(C, S, I) ~> continueCollect(E, F) ... </k>
       <explicit> ... E |-> C:Cause ... </explicit>
       <suppress> ... E |-> S:Bool ... </suppress>
       <context> ... E |-> I:Cause ... </context>
    requires E =/=K none andBool F >Int 0

  rule <k> NEXT:Cause ~> continueCollect(E:Cause, F:Int) => collect(NEXT, F -Int 1) ... </k>
       <seen> SEEN => SEEN ListItem(E) </seen>
endmodule
