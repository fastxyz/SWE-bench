module MINI-STATICFILES-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Bools ::= ".Bools"
                 | Bool ";" Bools [right]

  syntax Result ::= ok(Bool)
                  | maxExceeded
                  | unboundLocal

  syntax Exp ::= postProcessTail(Int, Bools)
               | legacyPostProcessTail(Int, Bools)
               | resultForFinal(Bool)
endmodule

module MINI-STATICFILES
  imports MINI-STATICFILES-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= finalSubstitutions(Int, Bools) [function]
  rule finalSubstitutions(0, _BS) => false
  rule finalSubstitutions(P, .Bools) => false requires P >Int 0
  rule finalSubstitutions(P, false ; _BS) => false requires P >Int 0
  rule finalSubstitutions(1, true ; _BS) => true
  rule finalSubstitutions(P, true ; BS) => finalSubstitutions(P -Int 1, BS)
    requires P >Int 1

  rule <k> postProcessTail(P, BS) => resultForFinal(finalSubstitutions(P, BS)) ... </k>
    requires P >=Int 0

  rule <k> legacyPostProcessTail(0, _BS) => unboundLocal ... </k>

  rule <k> legacyPostProcessTail(P, BS) => resultForFinal(finalSubstitutions(P, BS)) ... </k>
    requires P >Int 0

  rule <k> resultForFinal(false) => ok(false) ... </k>
  rule <k> resultForFinal(true) => maxExceeded ... </k>
endmodule
