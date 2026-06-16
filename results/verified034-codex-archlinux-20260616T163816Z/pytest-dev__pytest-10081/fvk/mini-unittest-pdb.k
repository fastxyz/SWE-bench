module MINI-UNITTEST-PDB-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Action ::= "run" "(" Bool "," Bool "," Bool "," Bool ")"
                  | "finish"

  syntax KResult ::= Bool | Int
endmodule

module MINI-UNITTEST-PDB
  imports MINI-UNITTEST-PDB-SYNTAX
  imports BOOL
  imports INT

  configuration
    <k> $PGM:Action </k>
    <explicit> false </explicit>
    <tdcount> 0 </tdcount>

  // run(USEPDB, ASYNC, METHOD_SKIPPED, CASE_SKIPPED)
  // A skipped unittest test reports skip before setUp/test/tearDown.
  rule <k> run(USE:Bool, ASYNC:Bool, METHOD:Bool, CASE:Bool) => finish ... </k>
       <explicit> _ => false </explicit>
    requires METHOD orBool CASE

  // V1 delayed-teardown condition for the synchronous, non-skipped --pdb path.
  rule <k> run(true, false, false, false) => finish ... </k>
       <explicit> _ => true </explicit>

  // Non-delayed, non-skipped paths use unittest's normal teardown path.
  rule <k> run(USE:Bool, ASYNC:Bool, false, false) => finish ... </k>
       <explicit> _ => false </explicit>
       <tdcount> C:Int => C +Int 1 </tdcount>
    requires (notBool USE) orBool ASYNC

  // pytest item teardown calls the saved original tearDown exactly once.
  rule <k> finish => .K ... </k>
       <explicit> true => false </explicit>
       <tdcount> C:Int => C +Int 1 </tdcount>

  rule <k> finish => .K ... </k>
       <explicit> false </explicit>
endmodule
