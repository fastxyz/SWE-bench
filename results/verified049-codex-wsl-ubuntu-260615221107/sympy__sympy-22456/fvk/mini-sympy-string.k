requires "domains.md"

module MINI-SYMPY-STRING-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Class ::= "String" | "QuotedString" | "Comment" | "SubString"
  syntax Value ::= pyStr(String)
                 | strAtom(String)
                 | other
                 | typeError
                 | obj(Class, String, Args)
                 | kw(String)
                 | atomSet(Args)
  syntax Args ::= ".Args" | arg(Value) | Args Args [assoc, unit(.Args)]
  syntax Cmd ::= construct(Class, Value)
               | reconstruct(Value)
               | kwargs(Value)
               | atomsDefault(Value)
  syntax KResult ::= Value | Args
endmodule

module MINI-SYMPY-STRING
  imports MINI-SYMPY-STRING-SYNTAX
  imports BOOL

  configuration <k> $PGM:Cmd </k>

  syntax Bool ::= isBasic(Value) [function]
  rule isBasic(strAtom(_)) => true
  rule isBasic(obj(_, _, _)) => true
  rule isBasic(pyStr(_)) => false
  rule isBasic(other) => false
  rule isBasic(typeError) => false
  rule isBasic(kw(_)) => false
  rule isBasic(atomSet(_)) => false

  syntax Bool ::= allBasic(Args) [function]
  rule allBasic(.Args) => true
  rule allBasic(arg(V) REST) => isBasic(V) andBool allBasic(REST)

  // Public construction from Python str: keep public text as a string, but
  // expose a Basic-compatible Str wrapper in args.
  rule <k> construct(C:Class, pyStr(S:String)) => obj(C, S, arg(strAtom(S))) </k>

  // Reconstruction from .args: the Str wrapper normalizes back to public text.
  rule <k> construct(C:Class, strAtom(S:String)) => obj(C, S, arg(strAtom(S))) </k>

  // Other public text inputs remain invalid.
  rule <k> construct(_:Class, other) => typeError </k>

  // func(*args) for a String-like object.
  rule <k> reconstruct(obj(C:Class, _:String, arg(strAtom(S:String))))
        => construct(C, strAtom(S)) </k>

  // kwargs() observes the public text slot, not the internal Str wrapper.
  rule <k> kwargs(obj(_:Class, S:String, _:Args)) => kw(S) </k>

  // Default codegen atom collection treats String objects as leaves.
  rule <k> atomsDefault(obj(C:Class, S:String, A:Args))
        => atomSet(arg(obj(C, S, A))) </k>
endmodule
