module MINI-PYTHON-SYNTAX
  imports BOOL-SYNTAX

  syntax Equation ::= "pow4_mn_2_3" [token]
                    | "EQ" [token]

  syntax Param ::= "tparam" [token]
                 | "PARAM" [token]

  syntax SymList ::= "noSyms" [token]
                   | "mn" [token]
                   | "nm" [token]
                   | "vars" "(" Equation ")" [function]

  syntax SolSet ::= "pow4_base_mn" [token]
                  | "pow4_base_nm" [token]
                  | "pow4_signed_mn" [token]
                  | "pow4_signed_nm" [token]
                  | "canonical" "(" Equation "," Param "," Bool ")" [function]
                  | "reorder" "(" SymList "," SymList "," SolSet ")" [function]

  syntax Bool ::= "completeSyms" "(" SymList "," SymList ")" [function]
                | "sameOrder" "(" SymList "," SymList ")" [function]
                | "needsReorder" "(" SymList "," SymList ")" [function]

  syntax Exp ::= SolSet
               | "diophantine" "(" Equation "," Param "," SymList "," Bool ")"

  syntax KResult ::= SolSet
  syntax KItem ::= "remap" "(" SymList "," SymList ")"
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:K </k>

  // syms omitted: this abstracts the normal canonical solve path.
  rule <k> diophantine(EQ:Equation, P:Param, noSyms, PERM:Bool)
           => canonical(EQ, P, PERM) ... </k>

  // syms supplied in canonical order: no recursive remap is needed.
  rule <k> diophantine(EQ:Equation, P:Param, SYMS:SymList, PERM:Bool)
           => canonical(EQ, P, PERM) ... </k>
       requires completeSyms(SYMS, vars(EQ)) andBool sameOrder(SYMS, vars(EQ))

  // syms supplied in a different complete order: solve canonically, preserving
  // PERM across the recursive call, then remap tuple positions.
  rule <k> diophantine(EQ:Equation, P:Param, SYMS:SymList, PERM:Bool)
           => diophantine(EQ, P, noSyms, PERM) ~> remap(vars(EQ), SYMS) ... </k>
       requires completeSyms(SYMS, vars(EQ)) andBool needsReorder(SYMS, vars(EQ))

  rule <k> SOL:SolSet ~> remap(VARORDER:SymList, SYMS:SymList)
           => reorder(VARORDER, SYMS, SOL) ... </k>
endmodule
