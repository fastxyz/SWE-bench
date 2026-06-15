module MINI-FITSDIFF-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Format ::= "P" | "Q" | "OTHER"
  syntax Kind ::= "FLOAT" | "NUMBER" | "NONNUM"

  // row(SameShape, Kind, FloatClose, NumClose, ExactEqual)
  syntax Row ::= row(Bool, Kind, Bool, Bool, Bool)
  syntax Rows ::= ".Rows" | Row ";" Rows [right]

  syntax Bool ::= isVLA(Format) [function]
                | vlaValuesDiffer(Row) [function]
  syntax Int ::= rowContribution(Bool, Bool) [function]
               | rowDiffCount(Format, Rows) [function]
  syntax KResult ::= Bool | Int
endmodule

module MINI-FITSDIFF
  imports MINI-FITSDIFF-SYNTAX
  imports BOOL
  imports INT

  configuration <k> $PGM:K </k>

  rule isVLA(P) => true
  rule isVLA(Q) => true
  rule isVLA(OTHER) => false

  rule vlaValuesDiffer(row(false, K:Kind, FC:Bool, NC:Bool, EC:Bool)) => true
  rule vlaValuesDiffer(row(true, FLOAT, FC:Bool, NC:Bool, EC:Bool)) => notBool FC
  rule vlaValuesDiffer(row(true, NUMBER, FC:Bool, NC:Bool, EC:Bool)) => notBool NC
  rule vlaValuesDiffer(row(true, NONNUM, FC:Bool, NC:Bool, EC:Bool)) => notBool EC

  rule rowDiffCount(F:Format, .Rows) => 0
  rule rowDiffCount(F:Format, R:Row ; RS:Rows)
    => rowContribution(isVLA(F), vlaValuesDiffer(R)) +Int rowDiffCount(F, RS)

  rule rowContribution(true, true) => 1
  rule rowContribution(true, false) => 0
  rule rowContribution(false, D:Bool) => 0
endmodule
