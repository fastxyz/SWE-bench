module MINI-HOMOMORPHISM-SYNTAX
  imports INT-SYNTAX

  syntax Sym
  syntax Gen
  syntax Elem

  syntax Syllable ::= "(" Sym "," Int ")"
  syntax Relator ::= ".Rel" | Syllable Relator [right]

  syntax PMap
  syntax IMap

  syntax Gen  ::= "lookupP" "(" PMap "," Sym ")" [function]
  syntax Elem ::= "lookupI" "(" IMap "," Gen ")" [function]
  syntax Elem ::= "id"
                | Elem "*" Elem
                | Elem "^" Int
                | "eval" "(" Relator "," PMap "," IMap "," Elem ")" [function]
endmodule

module MINI-HOMOMORPHISM
  imports MINI-HOMOMORPHISM-SYNTAX

  // Abstract semantics for _image(): fold a relator's array_form from left to
  // right, mapping the presentation symbol first and using the signed exponent.
  rule eval(.Rel, P:PMap, I:IMap, W:Elem) => W
  rule eval((SYM:Sym, POW:Int) REST:Relator, P:PMap, I:IMap, W:Elem)
    => eval(REST, P, I, W * (lookupI(I, lookupP(P, SYM)) ^ POW))
endmodule
