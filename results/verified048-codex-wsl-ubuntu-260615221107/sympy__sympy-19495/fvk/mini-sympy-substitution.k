// Constructed mini semantics for the audited ConditionSet._eval_subs branch.
// This is an abstract model of the relevant SymPy substitution state, not a
// full Python or full SymPy semantics. It is constructed, not machine-checked.

module MINI-SYMPY-SUBSTITUTION-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax SymLike ::= Sym(Id) | ExprSym(Id)
  syntax Value ::= Val(Id)
  syntax Cond ::= TrueCond
                | FalseCond
                | Cond(Id)
                | ContainsCond(Value, SetObj)
  syntax SetObj ::= Base(Id)
                  | ImageSetObj(Id)
                  | ConditionSetObj(SymLike, Cond, SetObj)
                  | ConditionSetValueObj(Value, Cond, SetObj)
  syntax Cmd ::= EvalSubs(SymLike, Cond, SetObj, Id, Value)

  syntax KResult ::= SetObj
endmodule

module MINI-SYMPY-SUBSTITUTION
  imports MINI-SYMPY-SUBSTITUTION-SYNTAX
  imports BOOL
  imports K-EQUAL

  configuration <k> $PGM:Cmd </k>

  syntax Bool ::= oldIsSym(Id, SymLike) [function]
  syntax Bool ::= dependsOn(SymLike, Cond) [function]
  syntax Cond ::= subCond(Cond, Id, Value) [function]
  syntax SetObj ::= subSet(SetObj, Id, Value) [function]

  // The public issue and V1 fix concern only old != self.sym.
  // The old == self.sym branch is intentionally a frame obligation in SPEC.md.

  rule <k> EvalSubs(SYM, COND, BASE, OLD, NEW)
        => subSet(BASE, OLD, NEW) ... </k>
    requires oldIsSym(OLD, SYM) ==Bool false
     andBool subCond(COND, OLD, NEW) ==K TrueCond
     andBool dependsOn(SYM, COND) ==Bool false

  rule <k> EvalSubs(SYM, COND, BASE, OLD, NEW)
        => ConditionSetValueObj(NEW,
             ContainsCond(NEW, subSet(BASE, OLD, NEW)),
             subSet(BASE, OLD, NEW)) ... </k>
    requires oldIsSym(OLD, SYM) ==Bool false
     andBool subCond(COND, OLD, NEW) ==K TrueCond
     andBool dependsOn(SYM, COND) ==Bool true

  rule <k> EvalSubs(SYM, COND, BASE, OLD, NEW)
        => ConditionSetObj(SYM,
             subCond(COND, OLD, NEW),
             subSet(BASE, OLD, NEW)) ... </k>
    requires oldIsSym(OLD, SYM) ==Bool false
     andBool notBool (subCond(COND, OLD, NEW) ==K TrueCond)
endmodule

