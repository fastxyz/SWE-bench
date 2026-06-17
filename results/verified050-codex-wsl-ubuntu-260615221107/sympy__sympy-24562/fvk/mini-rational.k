module MINI-RATIONAL-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax GcdMode ::= "autoGcd" | "keepGcd"
  syntax Result ::= "noResult"
                  | "rat" "(" Int "," Int ")"
                  | "integer" "(" Int ")"
                  | "half"
                  | "complexInfinity"
                  | "nan"
                  | "valueError"
                  | "canonical" "(" Int "," Int "," GcdMode "," Bool ")" [function]

  syntax KItem ::= "normalize" "(" Int "," Int "," Int "," Int "," GcdMode "," Bool ")"
                 | "finish" "(" Int "," Int "," GcdMode "," Bool ")"
endmodule

module MINI-RATIONAL
  imports MINI-RATIONAL-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:K </k>
    <result> noResult </result>

  rule canonical(1, 200, autoGcd, ERR:Bool) => rat(1, 200)

  // Input to normalize is the already-converted pair:
  // p = PN/PD, q = QN/QD, with PD > 0 and QD > 0.
  // This is the property-bearing abstraction: it distinguishes the
  // good reported result rat(1, 200) from the bad legacy rat(1, 100100).
  rule
    <k> normalize(PN:Int, PD:Int, QN:Int, QD:Int, MODE:GcdMode, ERR:Bool)
      => finish(PN *Int QD, PD *Int QN, MODE, ERR) ... </k>
    requires PD >Int 0 andBool QD >Int 0

  rule
    <k> finish(0, 0, MODE:GcdMode, true) => .K ... </k>
    <result> noResult => valueError </result>

  rule
    <k> finish(0, 0, MODE:GcdMode, false) => .K ... </k>
    <result> noResult => nan </result>

  rule
    <k> finish(P:Int, 0, MODE:GcdMode, ERR:Bool) => .K ... </k>
    <result> noResult => complexInfinity </result>
    requires P =/=Int 0

  rule
    <k> finish(P:Int, Q:Int, MODE:GcdMode, ERR:Bool)
      => finish(0 -Int P, 0 -Int Q, MODE, ERR) ... </k>
    requires Q <Int 0

  rule
    <k> finish(P:Int, Q:Int, MODE:GcdMode, ERR:Bool) => .K ... </k>
    <result> noResult => canonical(P, Q, MODE, ERR) </result>
    requires Q >Int 0
endmodule
