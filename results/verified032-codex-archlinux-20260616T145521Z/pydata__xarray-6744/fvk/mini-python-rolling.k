module MINI-PYTHON-ROLLING-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Bounds ::= "pair" "(" Int "," Int ")"
  syntax Exp ::= "rollingBounds" "(" Int "," Int "," Bool "," Int ")"

  syntax KResult ::= Bounds
endmodule

module MINI-PYTHON-ROLLING
  imports MINI-PYTHON-ROLLING-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Int ::= "maxInt" "(" Int "," Int ")" [function]
  rule maxInt(A:Int, B:Int) => A requires A >=Int B
  rule maxInt(A:Int, B:Int) => B requires A <Int B

  syntax Int ::= "minInt" "(" Int "," Int ")" [function]
  rule minInt(A:Int, B:Int) => A requires A <=Int B
  rule minInt(A:Int, B:Int) => B requires A >Int B

  // Model of the V1 DataArrayRolling.__iter__ bound calculation for one
  // zero-based output position I in an array of length N and window size W.
  // The full iterator frames labels, slicing, and min_periods masking around
  // these bounds; the reported defect is exactly in these arithmetic bounds.
  rule <k> rollingBounds(N:Int, W:Int, false, I:Int)
        => pair(maxInt(I +Int 1 -Int W, 0), minInt(I +Int 1, N)) </k>

  rule <k> rollingBounds(N:Int, W:Int, true, I:Int)
        => pair(
             maxInt(I +Int 1 +Int ((W -Int 1) /Int 2) -Int W, 0),
             minInt(I +Int 1 +Int ((W -Int 1) /Int 2), N)
           )
       </k>
endmodule
