module MINI-SPHINX-GLOSSARY-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX
  imports LIST-SYNTAX

  syntax Label ::= label(String, String)
  syntax MaybeLabel ::= some(Label) | none
  syntax XRef ::= xref(String, String)  // compatibility reftarget, original target
  syntax Event ::= duplicate(String)

  syntax Stmt ::= registerTerm(String, Label)
                | makeTermRef(String)
                | resolveTerm(String)
                | resolveNode(XRef)

  syntax KResult ::= Label | MaybeLabel | XRef | Bool
endmodule

module MINI-SPHINX-GLOSSARY
  imports MINI-SPHINX-GLOSSARY-SYNTAX
  imports STRING
  imports BOOL
  imports MAP
  imports LIST

  configuration
    <k> $PGM:K </k>
    <objects> .Map </objects>
    <warnings> .List </warnings>
    <result> none </result>

  syntax String ::= norm(String) [function]
                  | lower(String) [function]
  syntax Bool ::= hasExactTerm(Map, String) [function]
  syntax Map ::= putTerm(Map, String, Label) [function]
  syntax MaybeLabel ::= resolveTermIn(Map, String) [function]

  rule <k> registerTerm(T, L) => .K ... </k>
       <objects> OBJ => putTerm(OBJ, T, L) </objects>
       <warnings> W => W ListItem(duplicate(T)) </warnings>
    requires hasExactTerm(OBJ, T)

  rule <k> registerTerm(T, L) => .K ... </k>
       <objects> OBJ => putTerm(OBJ, T, L) </objects>
       <warnings> W => W </warnings>
    requires notBool hasExactTerm(OBJ, T)

  rule <k> makeTermRef(T) => .K ... </k>
       <result> _ => xref(lower(norm(T)), norm(T)) </result>

  rule <k> resolveNode(xref(_, Original)) => resolveTerm(Original) ... </k>

  rule <k> resolveTerm(T) => .K ... </k>
       <objects> OBJ </objects>
       <result> _ => resolveTermIn(OBJ, T) </result>
endmodule
