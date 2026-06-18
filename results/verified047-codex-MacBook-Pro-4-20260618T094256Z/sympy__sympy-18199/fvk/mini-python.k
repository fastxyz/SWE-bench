module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Val ::= Int
               | Bool
               | List
               | "None"
               | "NotImplemented"
               | "sqrtResult" "(" Int "," Int "," Bool ")"
               | "nonzeroResult" "(" Int "," Int "," Int "," Bool ")"

  syntax Exp ::= Val
               | "is_nthpow_residue" "(" Int "," Int "," Int ")"
               | "nthroot_mod" "(" Int "," Int "," Int "," Bool ")"
               | "zeroRootResult" "(" Bool ")"

  syntax KResult ::= Val
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= "isPrime" "(" Int ")" [function, smtlib(isPrime)]
  syntax Bool ::= "nthResidue" "(" Int "," Int "," Int ")" [function, smtlib(nthResidue)]

  // Implementation model for is_nthpow_residue's zero-residue branch.
  rule <k> is_nthpow_residue(A:Int, N:Int, M:Int) => true ... </k>
    requires M >Int 0 andBool N >Int 0 andBool A >=Int 0 andBool A modInt M ==Int 0

  // V2 dispatch model for nthroot_mod. It preserves the square-root path first.
  rule <k> nthroot_mod(A:Int, 2, P:Int, AR:Bool) => sqrtResult(A, P, AR) ... </k>

  // V2 handles zero residues before is_nthpow_residue so negative multiples of p
  // do not hit that helper's a >= 0 guard.
  rule <k> nthroot_mod(A:Int, N:Int, P:Int, AR:Bool) => NotImplemented ... </k>
    requires N =/=Int 2 andBool N >Int 0 andBool P >Int 0
     andBool A modInt P ==Int 0 andBool notBool isPrime(P)

  rule <k> nthroot_mod(A:Int, N:Int, P:Int, AR:Bool) => zeroRootResult(AR) ... </k>
    requires N =/=Int 2 andBool N >Int 0 andBool P >Int 0
     andBool A modInt P ==Int 0 andBool isPrime(P)

  rule <k> zeroRootResult(false) => 0 ... </k>
  rule <k> zeroRootResult(true) => ListItem(0) ... </k>

  // Remaining branches are unchanged compatibility frames.
  rule <k> nthroot_mod(A:Int, N:Int, P:Int, AR:Bool) => None ... </k>
    requires N =/=Int 2 andBool notBool nthResidue(A, N, P)

  rule <k> nthroot_mod(A:Int, N:Int, P:Int, AR:Bool) => NotImplemented ... </k>
    requires N =/=Int 2 andBool nthResidue(A, N, P) andBool notBool isPrime(P)
     andBool notBool (N >Int 0 andBool P >Int 0 andBool A modInt P ==Int 0)

  rule <k> nthroot_mod(A:Int, N:Int, P:Int, AR:Bool) => nonzeroResult(A, N, P, AR) ... </k>
    requires N =/=Int 2 andBool nthResidue(A, N, P) andBool isPrime(P)
     andBool notBool (N >Int 0 andBool P >Int 0 andBool A modInt P ==Int 0)
endmodule
