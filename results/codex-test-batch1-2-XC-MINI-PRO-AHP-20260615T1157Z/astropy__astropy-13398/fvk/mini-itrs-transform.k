module MINI-ITRS-TRANSFORM-SYNTAX
  syntax Vec ::= vec(Int, Int, Int)
  syntax Bool ::= "warned" | "silent"
endmodule

module MINI-ITRS-TRANSFORM
  imports INT
  imports BOOL
  imports MINI-ITRS-TRANSFORM-SYNTAX

  syntax Vec ::= add(Vec, Vec) [function]
               | sub(Vec, Vec) [function]

  rule add(vec(X1, Y1, Z1), vec(X2, Y2, Z2)) => vec(X1 +Int X2, Y1 +Int Y2, Z1 +Int Z2)
  rule sub(vec(X1, Y1, Z1), vec(X2, Y2, Z2)) => vec(X1 -Int X2, Y1 -Int Y2, Z1 -Int Z2)

  syntax Vec ::= originShift(Vec, Vec, Vec) [function]
  rule originShift(P, Lsrc, Ldst) => sub(add(P, Lsrc), Ldst)

  syntax Bool ::= mismatchWarn(Int, Int) [function]
  rule mismatchWarn(T1, T2) => true requires T1 =/=Int T2
  rule mismatchWarn(T, T) => false
endmodule
