module MINI-COLORBAR-SEGMENTS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Extend ::= "ExtNeither" | "ExtMin" | "ExtMax" | "ExtBoth"
  syntax Segments ::= "emptySegments"
                    | "range" "(" Int "," Int ")"
  syntax Exp ::= "select" "(" Bool "," Extend "," Int ")"
  syntax KResult ::= Segments
endmodule

module MINI-COLORBAR-SEGMENTS
  imports MINI-COLORBAR-SEGMENTS-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // The third argument is N, the number of boundary rows in
  // np.dstack([X, Y]).  range(A, B) denotes Python's half-open slice
  // of selected boundary-row indices [A, ..., B - 1].
  rule <k> select(false, _E:Extend, _N:Int) => emptySegments ... </k>

  rule <k> select(true, ExtNeither, N:Int) => range(1, N -Int 1) ... </k>
    requires N >=Int 2

  rule <k> select(true, ExtMin, N:Int) => range(0, N -Int 1) ... </k>
    requires N >=Int 2

  rule <k> select(true, ExtMax, N:Int) => range(1, N) ... </k>
    requires N >=Int 2

  rule <k> select(true, ExtBoth, N:Int) => range(0, N) ... </k>
    requires N >=Int 2
endmodule
