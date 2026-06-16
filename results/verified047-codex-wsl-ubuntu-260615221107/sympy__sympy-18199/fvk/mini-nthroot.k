module MINI-NTHROOT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax KItem ::= nthrootMod(Int, Int, Int, Bool, Bool, Bool)
  syntax RootResult ::= Single(Int)
                      | ZeroList
                      | NoneRoot
                      | NotImplemented
                      | SqrtDelegated
                      | ResidualDelegated
  syntax KResult ::= RootResult
endmodule

module MINI-NTHROOT
  imports MINI-NTHROOT-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  // nthrootMod(A, N, P, AllRoots, IsResidue, IsPrime) models the
  // dispatch prefix of sympy.ntheory.residue_ntheory.nthroot_mod after
  // integer coercion. IsResidue abstracts is_nthpow_residue(A, N, P),
  // and IsPrime abstracts isprime(P).
  rule <k> nthrootMod(A, 2, P, AllRoots, IsResidue, IsPrime)
        => SqrtDelegated ... </k>

  rule <k> nthrootMod(A, N, P, AllRoots, false, IsPrime)
        => NoneRoot ... </k>
    requires N =/=Int 2

  rule <k> nthrootMod(A, N, P, AllRoots, true, false)
        => NotImplemented ... </k>
    requires N =/=Int 2

  rule <k> nthrootMod(A, N, P, false, true, true)
        => Single(0) ... </k>
    requires N =/=Int 2
     andBool P >Int 1
     andBool A modInt P ==Int 0

  rule <k> nthrootMod(A, N, P, true, true, true)
        => ZeroList ... </k>
    requires N =/=Int 2
     andBool P >Int 1
     andBool A modInt P ==Int 0

  rule <k> nthrootMod(A, N, P, AllRoots, true, true)
        => ResidualDelegated ... </k>
    requires N =/=Int 2
     andBool P >Int 1
     andBool A modInt P =/=Int 0
endmodule
