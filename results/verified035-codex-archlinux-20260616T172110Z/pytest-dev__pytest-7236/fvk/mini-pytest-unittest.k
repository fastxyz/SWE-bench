requires "domains.md"

module MINI-PYTEST-UNITTEST-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Slot ::= "none" | "saved"
  syntax KItem ::= "setup"
                 | "runtest" "(" Bool "," Bool ")"
                 | "teardown"
                 | "maybeRecord" "(" Bool ")"
                 | "maybeCall" "(" Slot ")"
endmodule

module MINI-PYTEST-UNITTEST
  imports MINI-PYTEST-UNITTEST-SYNTAX
  imports BOOL
  imports INT

  configuration
    <k> $PGM:K </k>
    <explicit> none </explicit>
    <delayedCalls> 0 </delayedCalls>

  rule <k> setup => .K ... </k>
       <explicit> (_:Slot) => none </explicit>

  rule <k> runtest(false, _:Bool) => .K ... </k>

  rule <k> runtest(true, UTCalls:Bool) => maybeRecord(UTCalls) ... </k>

  rule <k> maybeRecord(false) => .K ... </k>

  rule <k> maybeRecord(true) => .K ... </k>
       <explicit> (_:Slot) => saved </explicit>

  rule <k> teardown => maybeCall(E) ... </k>
       <explicit> E:Slot </explicit>

  rule <k> maybeCall(none) => .K ... </k>

  rule <k> maybeCall(saved) => .K ... </k>
       <explicit> saved => none </explicit>
       <delayedCalls> N:Int => N +Int 1 </delayedCalls>
endmodule
