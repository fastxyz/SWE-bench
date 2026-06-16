module MINI-PIE800-FIXER-SYNTAX
  imports INT-SYNTAX

  syntax Pos ::= "only" | "first" | "middle" | "last"
  syntax Shape ::= "nonEmpty" "(" Int ")"
                 | "empty" "(" Pos "," Int ")"
  syntax Result ::= "valid"
  syntax Exp ::= "fix" "(" Shape ")"
  syntax KResult ::= Result
endmodule

module MINI-PIE800-FIXER
  imports MINI-PIE800-FIXER-SYNTAX
  imports INT

  configuration <k> $PGM:Exp </k>

  // Abstract token-shape semantics:
  // - the Int is the number of wrapper parentheses around the inner dict;
  // - valid means the edit removes matched wrappers and leaves valid item separators.
  rule <k> fix(nonEmpty(P:Int)) => valid </k>
    requires P >=Int 0

  rule <k> fix(empty(only, P:Int)) => valid </k>
    requires P >=Int 0

  rule <k> fix(empty(first, P:Int)) => valid </k>
    requires P >=Int 0

  rule <k> fix(empty(middle, P:Int)) => valid </k>
    requires P >=Int 0

  rule <k> fix(empty(last, P:Int)) => valid </k>
    requires P >=Int 0
endmodule
