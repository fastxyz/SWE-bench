module MINI-URLVALIDATOR-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Val ::= String | Other
  syntax Other ::= "other"
  syntax Outcome ::= "OK" | "VE"
  syntax KItem ::= validate(Val)

  syntax Bool ::= isStr(Val) [function]
                | hasUnsafe(Val) [function]
                | schemeAllowed(Val) [function]
                | directRegexOK(Val) [function]
                | splitOK(Val) [function]
                | punycodeOK(Val) [function]
                | fallbackRegexOK(Val) [function]
                | ipv6Bad(Val) [function]
                | hostTooLong(Val) [function]
endmodule

module MINI-URLVALIDATOR
  imports MINI-URLVALIDATOR-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  // SPEC-PROVENANCE:
  // - from_prompt: LF, CR, and tab are stripped by patched urlsplit().
  // - from_code: V1 checks unsafe chars before scheme parsing and urlsplit().
  rule <k> validate(V:Val) => VE </k>
    requires notBool isStr(V)

  rule <k> validate(V:Val) => VE </k>
    requires isStr(V) andBool hasUnsafe(V)

  rule <k> validate(V:Val) => VE </k>
    requires isStr(V)
     andBool notBool hasUnsafe(V)
     andBool notBool schemeAllowed(V)

  rule <k> validate(V:Val) => OK </k>
    requires isStr(V)
     andBool notBool hasUnsafe(V)
     andBool schemeAllowed(V)
     andBool directRegexOK(V)
     andBool notBool ipv6Bad(V)
     andBool notBool hostTooLong(V)

  rule <k> validate(V:Val) => OK </k>
    requires isStr(V)
     andBool notBool hasUnsafe(V)
     andBool schemeAllowed(V)
     andBool notBool directRegexOK(V)
     andBool splitOK(V)
     andBool punycodeOK(V)
     andBool fallbackRegexOK(V)
     andBool notBool hostTooLong(V)

  rule <k> validate(V:Val) => VE </k>
    requires isStr(V)
     andBool notBool hasUnsafe(V)
     andBool schemeAllowed(V)
     andBool notBool directRegexOK(V)
     andBool (notBool splitOK(V)
              orBool notBool punycodeOK(V)
              orBool notBool fallbackRegexOK(V))

  rule <k> validate(V:Val) => VE </k>
    requires isStr(V)
     andBool notBool hasUnsafe(V)
     andBool schemeAllowed(V)
     andBool (directRegexOK(V)
              orBool (splitOK(V) andBool punycodeOK(V) andBool fallbackRegexOK(V)))
     andBool (ipv6Bad(V) orBool hostTooLong(V))
endmodule
