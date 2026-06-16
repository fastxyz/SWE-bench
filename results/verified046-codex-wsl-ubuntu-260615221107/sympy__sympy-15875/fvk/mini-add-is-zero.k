module MINI-ADD-IS-ZERO-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Truth ::= "T" | "F" | "U"
  syntax SignCert ::= "SSPos" | "SSNeg" | "NoSS"
  syntax Exp ::= "addZero" "(" Bool "," Bool "," Truth "," Bool "," Int "," Truth "," SignCert ")"
  syntax KResult ::= Truth
endmodule

module MINI-ADD-IS-ZERO
  imports MINI-ADD-IS-ZERO-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // addZero(COMM, ALL_ZERO, REAL_ZERO, HAS_MAYBE, IM_COUNT, IM_ZERO, SIGN)
  // COMM: Add is commutative.
  // ALL_ZERO: all scanned terms are known real zero.
  // REAL_ZERO: zero status of the known-real part after removing real zeros.
  // HAS_MAYBE: at least one term is only known to be imaginary-or-zero.
  // IM_COUNT: number of definitely imaginary terms.
  // IM_ZERO: zero status of the sum of imaginary coefficients after multiplying by I.
  // SIGN: local certificate that all imaginary coefficients are same-sign nonzero.

  rule <k> addZero(false, ALL_ZERO:Bool, REAL_ZERO:Truth, HAS_MAYBE:Bool, IM_COUNT:Int, IM_ZERO:Truth, SIGN:SignCert) => U </k>

  rule <k> addZero(true, true, REAL_ZERO:Truth, HAS_MAYBE:Bool, IM_COUNT:Int, IM_ZERO:Truth, SIGN:SignCert) => T </k>

  rule <k> addZero(true, false, F, HAS_MAYBE:Bool, IM_COUNT:Int, IM_ZERO:Truth, SIGN:SignCert) => F </k>
  rule <k> addZero(true, false, U, HAS_MAYBE:Bool, IM_COUNT:Int, IM_ZERO:Truth, SIGN:SignCert) => U </k>

  rule <k> addZero(true, false, T, false, 0, IM_ZERO:Truth, SIGN:SignCert) => T </k>
  rule <k> addZero(true, false, T, true, IM_COUNT:Int, IM_ZERO:Truth, SIGN:SignCert) => U </k>

  rule <k> addZero(true, false, T, false, IM_COUNT:Int, T, SIGN:SignCert) => T </k>
    requires IM_COUNT >Int 0

  rule <k> addZero(true, false, T, false, 1, IM_ZERO:Truth, SIGN:SignCert) => F </k>

  rule <k> addZero(true, false, T, false, IM_COUNT:Int, IM_ZERO:Truth, SSPos) => F </k>
    requires IM_COUNT >Int 1
  rule <k> addZero(true, false, T, false, IM_COUNT:Int, IM_ZERO:Truth, SSNeg) => F </k>
    requires IM_COUNT >Int 1

  rule <k> addZero(true, false, T, false, IM_COUNT:Int, IM_ZERO:Truth, NoSS) => U </k>
    requires IM_COUNT >Int 1 andBool IM_ZERO =/=K T
endmodule
