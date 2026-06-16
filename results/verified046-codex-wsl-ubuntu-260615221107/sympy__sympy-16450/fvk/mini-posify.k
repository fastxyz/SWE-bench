// Constructed for FVK audit; not machine-checked in this environment.
// This is a deliberately small Mini-SymPy fragment for the posify
// replacement step. It models only the observable property under audit:
// a symbol/dummy name and its old-assumptions map.

module MINI-POSIFY-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax AVal ::= "trueA" | "falseA"
  syntax Sym ::= "sym" "(" String "," Map ")"
               | "dummy" "(" String "," Map ")"
  syntax Result ::= "result" "(" Sym "," Map ")"
  syntax KItem ::= "posifySymbol" "(" Sym ")"

  syntax Map ::= setPositive(Map) [function]
  syntax Bool ::= positiveUnknown(Map) [function]
  syntax Bool ::= positiveKnown(Map) [function]
  syntax Bool ::= consistentPositiveNarrowing(Map) [function]
endmodule

module MINI-POSIFY
  imports MINI-POSIFY-SYNTAX
  imports BOOL
  imports MAP

  configuration <k> $PGM:K </k>

  // Abstract counterpart of:
  //   assumptions = s.assumptions0
  //   assumptions['positive'] = True
  rule setPositive(A:Map) => A [ "positive" <- trueA ]

  // Unknown-positive branch: create a dummy from the whole original
  // assumptions0 map, with only positive overwritten to true.
  rule
    <k> posifySymbol(sym(N:String, A:Map))
        => result(dummy(N, setPositive(A)),
                  dummy(N, setPositive(A)) |-> sym(N, A))
        ... </k>
    requires positiveUnknown(A)
     andBool consistentPositiveNarrowing(A)

  // Known-positive or known-not-positive branch: no replacement.
  rule
    <k> posifySymbol(sym(N:String, A:Map))
        => result(sym(N, A), .Map)
        ... </k>
    requires positiveKnown(A)
endmodule
