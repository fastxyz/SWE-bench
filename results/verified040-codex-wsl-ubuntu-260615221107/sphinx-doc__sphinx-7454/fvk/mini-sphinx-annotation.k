module MINI-SPHINX-ANNOTATION-SYNTAX
  imports STRING-SYNTAX

  syntax RefType ::= "classRole" | "objRole"
  syntax XRef ::= xref(RefType, String)
  syntax Inv ::= "hasPyObjRoleNone"
  syntax Link ::= external(String) | plain(String)

  syntax KItem ::= makeXref(String)
                 | signatureLink(Inv, String)
                 | resolveWith(Inv)
                 | resolve(Inv, XRef)
endmodule

module MINI-SPHINX-ANNOTATION
  imports MINI-SPHINX-ANNOTATION-SYNTAX
  imports STRING

  configuration <k> $PGM:K </k>

  rule <k> makeXref("None") => xref(objRole, "None") ... </k>
  rule <k> makeXref(T:String) => xref(classRole, T) ... </k>
    requires T =/=String "None"

  rule <k> signatureLink(INV:Inv, T:String)
        => makeXref(T) ~> resolveWith(INV)
        ... </k>
  rule <k> XR:XRef ~> resolveWith(INV:Inv)
        => resolve(INV, XR)
        ... </k>

  rule <k> resolve(hasPyObjRoleNone, xref(objRole, "None"))
        => external("https://docs.python.org/3/library/constants.html#None")
        ... </k>

  rule <k> resolve(hasPyObjRoleNone, xref(classRole, "None"))
        => plain("None")
        ... </k>
endmodule
