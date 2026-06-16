module MINI-PYTHON-VECTOR-SYNTAX
  imports INT-SYNTAX

  syntax Comps ::= ".Comps"
                 | "comp" "(" Int ")"
                 | "merge" "(" Comps "," Comps ")" [function]

  syntax Val ::= Int
               | "Vec" "(" Comps ")"
               | "TypeError"

  syntax Exp ::= Val
               | "vectorAdd" "(" Exp "," Exp ")" [seqstrict]
               | "pyAdd" "(" Exp "," Exp ")" [seqstrict]
               | "mul" "(" Exp "," Exp ")" [seqstrict]
               | "sum2" "(" Exp "," Exp ")" [seqstrict]

  syntax KResult ::= Val
endmodule

module MINI-PYTHON-VECTOR
  imports MINI-PYTHON-VECTOR-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule merge(.Comps, Cs:Comps) => Cs
  rule merge(Cs:Comps, .Comps) => Cs

  // Model Vector.__mul__ / __rmul__ only for the issue-relevant scalar zero.
  rule <k> mul(0, Vec(_:Comps)) => Vec(.Comps) ... </k>

  // Model Vector.__add__ after V1: scalar zero is the additive identity.
  rule <k> vectorAdd(Vec(Cs:Comps), I:Int) => Vec(Cs) ... </k>
    requires I ==Int 0
  rule <k> vectorAdd(Vec(Cs:Comps), Vec(Ds:Comps)) => Vec(merge(Cs, Ds)) ... </k>
  rule <k> vectorAdd(Vec(_:Comps), I:Int) => TypeError ... </k>
    requires I =/=Int 0

  // Model Python binary addition dispatch for the sum() start value.
  rule <k> pyAdd(0, Vec(Cs:Comps)) => vectorAdd(Vec(Cs), 0) ... </k>
  rule <k> pyAdd(I:Int, Vec(_:Comps)) => TypeError ... </k>
    requires I =/=Int 0
  rule <k> pyAdd(Vec(Cs:Comps), V:Val) => vectorAdd(Vec(Cs), V) ... </k>

  // Model sum([x, y]) as Python's left fold from default start value 0.
  rule <k> sum2(V1:Val, V2:Val) => pyAdd(pyAdd(0, V1), V2) ... </k>
endmodule
