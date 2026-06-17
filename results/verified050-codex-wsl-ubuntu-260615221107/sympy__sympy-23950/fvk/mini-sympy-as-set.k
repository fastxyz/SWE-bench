// Mini SymPy as_set fragment.
// Status: constructed, not machine-checked.

module MINI-SYMPY-AS-SET-SYNTAX
  imports BOOL-SYNTAX

  syntax Sym ::= "x" | "y" | "z"
  syntax Obj ::= Sym
               | "nonSymbol"
               | "Reals"
               | "Integers"
               | "EmptySet"
               | "UniversalSet"
               | "ParamSet" "(" Sym ")"
               | "Contains" "(" Obj "," Obj ")"
               | "ConditionSet" "(" Sym "," Obj "," Obj ")"
               | "Boolean" "(" Sym ")"
               | "intersect" "(" Obj "," Obj ")"
               | "freeSymbol" "(" Obj ")"

  syntax Cmd ::= "containsAsSet" "(" Obj ")"
               | "booleanEvalAsSet" "(" Obj ")"
               | Obj

  syntax KResult ::= Obj
endmodule

module MINI-SYMPY-AS-SET
  imports MINI-SYMPY-AS-SET-SYNTAX

  configuration <k> $PGM:Cmd </k>

  syntax Bool ::= isSymbol(Obj) [function]
  rule isSymbol(x) => true
  rule isSymbol(y) => true
  rule isSymbol(z) => true
  rule isSymbol(nonSymbol) => false

  // V1 Contains.as_set branch for symbolic left operands.
  rule <k> containsAsSet(Contains(X:Sym, SET:Obj))
        => ConditionSet(X, Contains(X, SET), UniversalSet) ... </k>

  // V1 fallback for one-free-symbol Boolean values.
  rule <k> booleanEvalAsSet(Boolean(X:Sym))
        => ConditionSet(X, Boolean(X), UniversalSet) ... </k>

  // Existing ConditionSet normalization used by V1.
  rule <k> ConditionSet(X:Sym, Contains(X, SET:Obj), BASE:Obj)
        => intersect(SET, BASE) ... </k>

  // Existing Set identities relevant to the proof.
  rule <k> intersect(SET:Obj, UniversalSet) => SET ... </k>
  rule <k> intersect(EmptySet, SET:Obj) => EmptySet ... </k>
endmodule
