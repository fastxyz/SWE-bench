module MINI-AXIOS-HTTP-OPTIONS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Limit ::= finite(Int) | inf | omitted
  syntax Transport ::= custom | native | follow
  syntax KItem ::= compute(Limit, Bool, Bool)
  syntax Result ::= res(Transport, Limit)
  syntax KResult ::= Result
endmodule

module MINI-AXIOS-HTTP-OPTIONS
  imports MINI-AXIOS-HTTP-OPTIONS-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  syntax Bool ::= gtMinusOne(Limit) [function]
  rule gtMinusOne(finite(N:Int)) => N >Int -1
  rule gtMinusOne(inf) => true
  rule gtMinusOne(omitted) => false

  rule <k> compute(MBL:Limit, true, RD:Bool) => res(custom, MBL) ... </k>
    requires gtMinusOne(MBL)
  rule <k> compute(MBL:Limit, true, RD:Bool) => res(custom, omitted) ... </k>
    requires notBool gtMinusOne(MBL)

  rule <k> compute(MBL:Limit, false, true) => res(native, MBL) ... </k>
    requires gtMinusOne(MBL)
  rule <k> compute(MBL:Limit, false, true) => res(native, omitted) ... </k>
    requires notBool gtMinusOne(MBL)

  rule <k> compute(MBL:Limit, false, false) => res(follow, MBL) ... </k>
    requires gtMinusOne(MBL)
  rule <k> compute(MBL:Limit, false, false) => res(follow, inf) ... </k>
    requires notBool gtMinusOne(MBL)
endmodule
