module MINI-DJANGO-MANAGEMENT-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Cmd ::= "auto" | "nocheck" | "runserver" | "testserver"
  syntax Stmt ::= "run" "(" Cmd "," Bool ")"
                | "delegateRunserver" "(" Bool ")"
                | "done"
  syntax KResult ::= "done"
endmodule

module MINI-DJANGO-MANAGEMENT
  imports MINI-DJANGO-MANAGEMENT-SYNTAX
  imports BOOL
  imports INT

  configuration
    <k> $PGM:Stmt </k>
    <checks> 0 </checks>

  // Automatic BaseCommand.execute() checks.
  rule <k> run(auto, false) => done </k>
       <checks> N:Int => N +Int 1 </checks>
  rule <k> run(auto, true) => done </k>
       <checks> N:Int => N </checks>

  // Commands with no automatic or explicit system check in this issue slice.
  rule <k> run(nocheck, S:Bool) => done </k>
       <checks> N:Int => N </checks>

  // runserver performs checks explicitly in inner_run().
  rule <k> run(runserver, false) => done </k>
       <checks> N:Int => N +Int 1 </checks>
  rule <k> run(runserver, true) => done </k>
       <checks> N:Int => N </checks>

  // testserver delegates to runserver. The repaired code must preserve the
  // caller's skip flag instead of letting call_command() inject its default.
  rule <k> run(testserver, S:Bool) => delegateRunserver(S) </k>
  rule <k> delegateRunserver(S:Bool) => run(runserver, S) </k>
endmodule
