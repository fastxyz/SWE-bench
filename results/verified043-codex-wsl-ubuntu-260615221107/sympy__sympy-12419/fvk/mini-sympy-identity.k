requires "domains.md"

module MINI-SYMPY-IDENTITY-SYNTAX
  imports INT-SYNTAX

  syntax EqStatus ::= "eq" | "neq" | "unknown"
  syntax Entry ::= "one" | "zero" | "kd" "(" Int "," Int ")"
                 | "kdSym"
  syntax KItem ::= identityEntry(Int, Int, EqStatus)
                 | evalSumConst(Entry, Int, Int)
                 | evalSumExactInterval(Entry, Int, Int)
                 | nestedIdentitySum(Int)
endmodule

module MINI-SYMPY-IDENTITY
  imports MINI-SYMPY-IDENTITY-SYNTAX
  imports INT

  configuration <k> $PGM:K </k>

  rule <k> identityEntry(I, J, eq) => one ... </k>
  rule <k> identityEntry(I, J, neq) => zero ... </k>
  rule <k> identityEntry(I, J, unknown) => kdSym ... </k>

  rule <k> evalSumConst(one, A, B) => B -Int A +Int 1 ... </k>
    requires B -Int A >=Int 0

  rule <k> evalSumExactInterval(E, A, B) => evalSumConst(E, A, B) ... </k>
    requires B -Int A >=Int 0

  rule <k> nestedIdentitySum(N) => evalSumExactInterval(one, 0, N -Int 1) ... </k>
    requires N >=Int 1
endmodule

