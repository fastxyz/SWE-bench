module MINI-SYMPY-SURDS-SYNTAX
  imports BOOL-SYNTAX

  syntax Exp ::= zero | one | two | three | four
               | iUnit
               | sqrt2
               | cbrt2
               | sqrt2MinusI
               | docDen | docA | docB
               | add2(Exp, Exp)
               | neg(Exp)

  syntax Result ::= noMatch
                  | split(Exp, Exp, Exp)
                  | pair(Exp, Exp)

  syntax Cmd ::= sqrtMatch(Exp)
               | splitSurds(Exp)
               | radRat(Exp, Exp)

  syntax Bool ::= allPosRatSquares(Exp) [function]
                | hasSqrtPow(Exp) [function]

  syntax KResult ::= Exp | Result | Bool
endmodule

module MINI-SYMPY-SURDS
  imports MINI-SYMPY-SURDS-SYNTAX
  imports BOOL

  configuration <k> $PGM:Cmd </k>

  // The public issue witness: 4**2 is positive rational, I**2 is rational
  // non-positive, so this is not a regular real-surd sum.
  rule allPosRatSquares(add2(four, iUnit)) => false
  rule allPosRatSquares(add2(one, cbrt2)) => false
  rule allPosRatSquares(add2(one, sqrt2)) => true
  rule allPosRatSquares(docDen) => true

  rule hasSqrtPow(add2(four, iUnit)) => false
  rule hasSqrtPow(add2(one, cbrt2)) => false
  rule hasSqrtPow(add2(sqrt2, iUnit)) => true
  rule hasSqrtPow(docDen) => true

  // V1 _sqrt_match: do not call split_surds unless every addend square is
  // rational and positive.
  rule <k> sqrtMatch(E:Exp) => noMatch ... </k>
    requires notBool allPosRatSquares(E)

  // V1 split_surds: a no-surd Add returns the well-shaped sentinel tuple.
  rule <k> splitSurds(add2(four, iUnit))
        => split(one, zero, add2(four, iUnit)) ... </k>

  rule <k> splitSurds(add2(one, cbrt2))
        => split(one, zero, add2(one, cbrt2)) ... </k>

  // Supported mixed sqrt/complex denominator. This abstracts the old path
  // where split_surds finds sqrt(2) and leaves I in the companion part.
  rule <k> splitSurds(add2(sqrt2, iUnit))
        => split(two, one, iUnit) ... </k>

  // Supported documented regular-surd grouping.
  rule <k> splitSurds(docDen) => split(three, docA, docB) ... </k>

  // V1 rad_rationalize base/no-progress cases.
  rule <k> radRat(N:Exp, three) => pair(N, three) ... </k>

  rule <k> radRat(N:Exp, add2(four, iUnit))
        => pair(N, add2(four, iUnit)) ... </k>

  rule <k> radRat(N:Exp, add2(one, cbrt2))
        => pair(N, add2(one, cbrt2)) ... </k>

  // Existing supported sqrt path: one rationalizing step followed by the
  // non-Add base case.
  rule <k> radRat(one, add2(sqrt2, iUnit))
        => radRat(sqrt2MinusI, three) ... </k>
endmodule
