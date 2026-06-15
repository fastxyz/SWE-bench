module MINI-CDS-UNITS-SYNTAX
  imports ID-SYNTAX

  syntax Scale ::= "one" | "p1000" | "p1em7"
  syntax Unit  ::= Id
                 | Scale
                 | Scale "*" Unit        [left]
                 | Unit "*" Unit         [left]
                 | Unit "/" Unit         [left]
                 | "dex" "(" Unit ")"

  syntax UExp  ::= "unit" "(" Unit ")"
                 | "paren" "(" CExp ")"

  syntax CExp  ::= UExp
                 | "prod" "(" UExp "," CExp ")"
                 | "div" "(" UExp "," CExp ")"
                 | "inv" "(" UExp ")"

  syntax Main  ::= "main" "(" CExp ")"
                 | "scaled" "(" Scale "," CExp ")"
                 | "dexed" "(" CExp ")"

  syntax Sem   ::= "sem" "(" Unit "," Unit ")"
  syntax Unit  ::= "actual" "(" Sem ")" [function]
                 | "tail" "(" Sem ")"   [function]
                 | "evalMain" "(" Main ")" [function]
  syntax Sem   ::= "evalU" "(" UExp ")"  [function]
                 | "evalC" "(" CExp ")"  [function]
endmodule

module MINI-CDS-UNITS
  imports MINI-CDS-UNITS-SYNTAX

  // A semantic value stores:
  // - actual: the unit if this parsed expression is used as a complete value;
  // - tail: the product to use when this expression appears after a slash.
  rule actual(sem(A:Unit, T:Unit)) => A [simplification]
  rule tail(sem(A:Unit, T:Unit)) => T [simplification]

  rule evalU(unit(U:Unit)) => sem(U, U) [simplification]

  // Parentheses make a combined expression atomic to the surrounding division.
  rule evalU(paren(C:CExp)) => sem(actual(evalC(C)), actual(evalC(C))) [simplification]

  rule evalC(E:UExp) => evalU(E) [simplification]

  rule evalC(prod(E:UExp, C:CExp))
    => sem(actual(evalU(E)) * actual(evalC(C)),
           tail(evalU(E)) * tail(evalC(C)))
    [simplification]

  rule evalC(div(E:UExp, C:CExp))
    => sem(actual(evalU(E)) / tail(evalC(C)),
           tail(evalU(E)) * tail(evalC(C)))
    [simplification]

  rule evalC(inv(E:UExp))
    => sem(one / actual(evalU(E)), tail(evalU(E)))
    [simplification]

  rule evalMain(main(C:CExp)) => actual(evalC(C)) [simplification]
  rule evalMain(scaled(S:Scale, C:CExp)) => S * actual(evalC(C)) [simplification]
  rule evalMain(dexed(C:CExp)) => dex(actual(evalC(C))) [simplification]
endmodule
