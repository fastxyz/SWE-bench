// Abstract mini semantics for method_decorator metadata flow.
// Constructed, not machine-checked in this benchmark environment.

module MINI-METHOD-DECORATOR-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX

  syntax Attr ::= moduleAttr | nameAttr | qualnameAttr | docAttr | annotationsAttr
  syntax Attrs ::= ".Attrs" | Attr "," Attrs
  syntax Callable ::= method(Map)
                    | bound(Callable, String)
                    | partial(Callable, Map)
                    | decorated(String, Callable)
                    | copyAssigned(Callable, Callable)
                    | makeBoundCallable(Callable, String)
  syntax Bool ::= assignedEqual(Callable, Callable, Attrs) [function]
                | callableDescriptor(Callable) [function]
                | hasAttr(Callable, Attr) [function]
  syntax Map ::= projectAssigned(Map) [function]
endmodule

module MINI-METHOD-DECORATOR
  imports MINI-METHOD-DECORATOR-SYNTAX
  imports BOOL
  imports STRING
  imports MAP

  configuration <k> $PGM:Callable </k>

  rule <k> makeBoundCallable(METHOD:Callable, SELF:String)
        => copyAssigned(partial(bound(METHOD, SELF), .Map), METHOD) ... </k>

  rule <k> copyAssigned(partial(TARGET:Callable, _:Map), method(META:Map))
        => partial(TARGET, projectAssigned(META)) ... </k>
endmodule
