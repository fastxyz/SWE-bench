module MINI-DJANGO-TEMPLATE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Value ::= Int
                 | String
                 | lazyText(String)
                 | opaqueValue(String)

  syntax Exp ::= add(Value, Value)
               | addResolved(Value, Value)

  syntax KResult ::= Value
endmodule

module MINI-DJANGO-TEMPLATE
  imports MINI-DJANGO-TEMPLATE-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= isLazyText(Value) [function]
  rule isLazyText(lazyText(_:String)) => true
  rule isLazyText(_:Int) => false
  rule isLazyText(_:String) => false
  rule isLazyText(opaqueValue(_:String)) => false

  syntax Value ::= resolveText(Value) [function]
  rule resolveText(lazyText(S:String)) => S
  rule resolveText(V:Value) => V requires notBool isLazyText(V)

  // Abstract predicates/functions standing for Python's int() and native +.
  // The spec claims constrain their success/failure cases; no full Python
  // exception semantics is modeled in this mini fragment.
  syntax Bool ::= intable(Value) [function]
  syntax Int ::= toInt(Value) [function]
  syntax Bool ::= plusable(Value, Value) [function]
  syntax Value ::= plusResult(Value, Value) [function]

  rule <k> add(V:Value, A:Value)
        => addResolved(resolveText(V), resolveText(A)) ... </k>

  rule <k> addResolved(V:Value, A:Value)
        => toInt(V) +Int toInt(A) ... </k>
    requires intable(V) andBool intable(A)

  rule <k> addResolved(V:Value, A:Value)
        => plusResult(V, A) ... </k>
    requires notBool (intable(V) andBool intable(A))
     andBool plusable(V, A)

  rule <k> addResolved(V:Value, A:Value)
        => "" ... </k>
    requires notBool (intable(V) andBool intable(A))
     andBool notBool plusable(V, A)
endmodule

